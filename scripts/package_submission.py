"""Bundle the downloaded dataset and trained model for assessment delivery."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
from zipfile import ZipFile, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset", type=Path, default=ROOT / "ml/data/realwaste")
    parser.add_argument("--out", type=Path, default=ROOT / "artifacts")
    args = parser.parse_args()
    manifest_path = args.dataset / "source_manifest.json"
    if not manifest_path.exists():
        raise SystemExit("Download the dataset with python ml/download_dataset.py first")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    if not manifest.get("complete"):
        raise SystemExit("Dataset download is incomplete; resume it before packaging")
    for entry in manifest["images"]:
        image = args.dataset / entry["path"]
        if not image.exists() or hashlib.sha256(image.read_bytes()).hexdigest() != entry["processed_sha256"]:
            raise SystemExit(f"Dataset is missing or modified: {entry['path']}")
    args.out.mkdir(parents=True, exist_ok=True)
    dataset_archive = args.out / "campah-dataset.zip"
    with ZipFile(dataset_archive, "w", ZIP_DEFLATED) as archive:
        for entry in manifest["images"]:
            archive.write(args.dataset / entry["path"], entry["path"])
        for name in ["source_manifest.json", "selection.json"]:
            archive.write(args.dataset / name, name)
        archive.write(ROOT / "ml/DATASET.md", "DATASET.md")
    model_archive = args.out / "campah-ml.zip"
    with ZipFile(model_archive, "w", ZIP_DEFLATED) as archive:
        for path in sorted((ROOT / "ml").rglob("*")):
            if path.is_file() and "data" not in path.relative_to(ROOT / "ml").parts and "__pycache__" not in path.parts:
                archive.write(path, path.relative_to(ROOT))
    apk_dir = ROOT / "mobile/build/app/outputs/flutter-apk"
    for apk in apk_dir.glob("*.apk"):
        shutil.copyfile(apk, args.out / f"campah-{apk.name}")
    files = [path for path in args.out.iterdir() if path.is_file() and path.suffix in {".zip", ".apk"}]
    checksums = "\n".join(f"{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.name}" for path in sorted(files))
    (args.out / "SHA256SUMS.txt").write_text(checksums + "\n", encoding="utf-8")
    print(f"Packaged {len(manifest['images'])} verified images and model artifacts in {args.out}")
    print("APK is included only when a local build exists. Public deployment and narrated video are separate submission items.")


if __name__ == "__main__":
    main()
