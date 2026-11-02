"""Train and evaluate a three-class MobileNetV2 without leaking test images."""

import argparse
import hashlib
import json
import os
import random
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import torch
from PIL import Image
from sklearn.metrics import ConfusionMatrixDisplay, accuracy_score, classification_report, confusion_matrix
from sklearn.model_selection import train_test_split
from torch import nn
from torch.utils.data import DataLoader, Dataset
from torchvision import transforms
from torchvision.models import MobileNet_V2_Weights, mobilenet_v2

LABELS = ("Organic Waste", "Plastic Waste", "Paper Waste")
EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}


class ImageFiles(Dataset):
    def __init__(self, paths, labels, transform):
        self.paths = paths
        self.labels = labels
        self.transform = transform

    def __len__(self):
        return len(self.paths)

    def __getitem__(self, index):
        with Image.open(self.paths[index]) as image:
            tensor = self.transform(image.convert("RGB"))
        return tensor, self.labels[index]


def collect(root: Path):
    paths, labels, hashes = [], [], {}
    for class_index, label in enumerate(LABELS):
        folder = root / label
        if not folder.is_dir():
            raise SystemExit(f"Missing class folder: {folder}")
        for path in sorted(folder.rglob("*")):
            if path.suffix.lower() not in EXTENSIONS:
                continue
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            if digest in hashes:
                if hashes[digest] != class_index:
                    raise SystemExit(f"Conflicting labels for duplicate image: {path}")
                continue
            try:
                with Image.open(path) as image:
                    image.verify()
            except Exception:
                continue
            hashes[digest] = class_index
            paths.append(path)
            labels.append(class_index)
    counts = {label: labels.count(index) for index, label in enumerate(LABELS)}
    if len(paths) < 150 or min(counts.values()) < 50:
        raise SystemExit(f"Need >=150 unique valid images and >=50 per class; got {counts}")
    return paths, labels, counts


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", type=Path, default=Path("ml/data/realwaste"))
    parser.add_argument("--out", type=Path, default=Path("ml/artifacts"))
    parser.add_argument("--epochs", type=int, default=16)
    parser.add_argument("--batch-size", type=int, default=16)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--threads", type=int, default=min(4, os.cpu_count() or 1))
    parser.add_argument("--fine-tune-after", type=int, default=5)
    args = parser.parse_args()
    random.seed(args.seed)
    np.random.seed(args.seed)
    torch.manual_seed(args.seed)
    torch.set_num_threads(args.threads)
    args.out.mkdir(parents=True, exist_ok=True)
    paths, labels, counts = collect(args.data)
    indices = list(range(len(paths)))
    train_val, test = train_test_split(indices, test_size=0.15, stratify=labels, random_state=args.seed)
    train, val = train_test_split(train_val, test_size=0.15 / 0.85,
                                stratify=[labels[i] for i in train_val], random_state=args.seed)
    split = {"train": train, "validation": val, "test": test}
    (args.out / "split_manifest.json").write_text(json.dumps({
        name: [{"path": paths[i].relative_to(args.data).as_posix(), "label": LABELS[labels[i]], "sha256": hashlib.sha256(paths[i].read_bytes()).hexdigest()} for i in ids]
        for name, ids in split.items()
    }, indent=2), encoding="utf-8")

    normalize = transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
    train_transform = transforms.Compose([
        transforms.Resize((224, 224)), transforms.RandomHorizontalFlip(),
        transforms.RandomRotation(15), transforms.ColorJitter(brightness=0.15, contrast=0.15), transforms.ToTensor(), normalize,
    ])
    eval_transform = transforms.Compose([transforms.Resize((224, 224)), transforms.ToTensor(), normalize])
    def loader(ids, transform, shuffle=False):
        dataset = ImageFiles([paths[i] for i in ids], [labels[i] for i in ids], transform)
        return DataLoader(dataset, batch_size=args.batch_size, shuffle=shuffle, num_workers=0)

    train_loader = loader(train, train_transform, True)
    val_loader = loader(val, eval_transform)
    test_loader = loader(test, eval_transform)
    device = "cuda" if torch.cuda.is_available() else "cpu"
    model = mobilenet_v2(weights=MobileNet_V2_Weights.DEFAULT)
    for parameter in model.features.parameters():
        parameter.requires_grad = False
    model.classifier[1] = nn.Linear(model.last_channel, len(LABELS))
    model.to(device)
    optimizer = torch.optim.AdamW(model.classifier.parameters(), lr=0.001)
    loss_fn = nn.CrossEntropyLoss()
    best_accuracy = -1.0
    best_epoch = 0
    history = []
    for epoch in range(1, args.epochs + 1):
        if epoch == args.fine_tune_after + 1:
            for parameter in model.features[-3:].parameters():
                parameter.requires_grad = True
            optimizer = torch.optim.AdamW(filter(lambda p: p.requires_grad, model.parameters()), lr=0.0001)
        model.train()
        model.features.eval()  # Keep BatchNorm statistics stable with a small dataset.
        running_loss = 0.0
        for images, targets in train_loader:
            images, targets = images.to(device), targets.to(device)
            optimizer.zero_grad()
            loss = loss_fn(model(images), targets)
            loss.backward()
            optimizer.step()
            running_loss += float(loss.detach()) * len(targets)
        model.eval()
        actual, predicted = [], []
        with torch.inference_mode():
            for images, targets in val_loader:
                output = model(images.to(device)).argmax(dim=1).cpu().tolist()
                actual.extend(targets.tolist())
                predicted.extend(output)
        accuracy = accuracy_score(actual, predicted)
        history.append({"epoch": epoch, "train_loss": running_loss / len(train), "validation_accuracy": accuracy})
        print(f"Epoch {epoch}/{args.epochs}: loss={history[-1]['train_loss']:.4f}, validation accuracy={accuracy:.4f}", flush=True)
        if accuracy > best_accuracy:
            best_accuracy, best_epoch = accuracy, epoch
            torch.save({"model_state": model.cpu().state_dict(), "labels": LABELS, "architecture": "mobilenet_v2", "image_size": 224}, args.out / "best_model.pt")
            model.to(device)

    checkpoint = torch.load(args.out / "best_model.pt", map_location=device, weights_only=True)
    model.load_state_dict(checkpoint["model_state"])
    model.eval()
    actual, predicted = [], []
    with torch.inference_mode():
        for images, targets in test_loader:
            output = model(images.to(device)).argmax(dim=1).cpu().tolist()
            actual.extend(targets.tolist())
            predicted.extend(output)
    metrics = {
        "dataset_counts": counts,
        "split_counts": {name: len(ids) for name, ids in split.items()},
        "seed": args.seed,
        "architecture": "mobilenet_v2",
        "pretrained_weights": "MobileNet_V2_Weights.IMAGENET1K_V2",
        "torch_version": str(torch.__version__),
        "fine_tune_after": args.fine_tune_after,
        "best_epoch": best_epoch,
        "validation_accuracy": best_accuracy,
        "test_accuracy": accuracy_score(actual, predicted),
        "classification_report": classification_report(actual, predicted, labels=list(range(3)), target_names=LABELS, output_dict=True, zero_division=0),
        "confusion_matrix": confusion_matrix(actual, predicted, labels=list(range(3))).tolist(),
    }
    (args.out / "metrics.json").write_text(json.dumps(metrics, indent=2), encoding="utf-8")
    (args.out / "history.json").write_text(json.dumps(history, indent=2), encoding="utf-8")
    (args.out / "classification_report.txt").write_text(classification_report(actual, predicted, labels=list(range(3)), target_names=LABELS, zero_division=0), encoding="utf-8")
    manifest_path = args.data / "source_manifest.json"
    if manifest_path.exists():
        (args.out / "source_manifest.json").write_bytes(manifest_path.read_bytes())
    ConfusionMatrixDisplay.from_predictions(actual, predicted, labels=list(range(3)), display_labels=LABELS, xticks_rotation=30)
    plt.tight_layout()
    plt.savefig(args.out / "confusion_matrix.png", dpi=160)
    print(json.dumps({"test_accuracy": metrics["test_accuracy"], "test_count": len(test)}, indent=2))


if __name__ == "__main__":
    main()
