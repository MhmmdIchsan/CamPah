import io
import os
from functools import lru_cache
from pathlib import Path

from PIL import Image, ImageOps

LABELS = ("Organic Waste", "Plastic Waste", "Paper Waste")
DEFAULT_MODEL_PATH = Path(__file__).resolve().parents[2] / "ml" / "artifacts" / "best_model.pt"


@lru_cache(maxsize=1)
def load_model():
    path = Path(os.getenv("MODEL_PATH", str(DEFAULT_MODEL_PATH)))
    if not path.exists():
        return None
    import torch
    from torchvision.models import mobilenet_v2

    model = mobilenet_v2(weights=None)
    model.classifier[1] = torch.nn.Linear(model.last_channel, len(LABELS))
    checkpoint = torch.load(path, map_location="cpu", weights_only=True)
    if tuple(checkpoint["labels"]) != LABELS:
        raise ValueError("Model labels do not match API labels")
    model.load_state_dict(checkpoint["model_state"])
    model.eval()
    return model


def predict(data: bytes) -> tuple[str, float] | None:
    model = load_model()
    if model is None:
        return None
    import torch
    from torchvision import transforms

    transform = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225]),
    ])
    image = ImageOps.exif_transpose(Image.open(io.BytesIO(data))).convert("RGB")
    with torch.inference_mode():
        probabilities = model(transform(image).unsqueeze(0)).softmax(dim=1)[0]
    index = int(probabilities.argmax())
    return LABELS[index], float(probabilities[index])
