"""Download a reproducible, attributed subset from the public Mendeley dataset."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import io
import json
from pathlib import Path
import random

from PIL import Image, ImageOps
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

DATASET_ID = "d4vsy9c9wk"
BASE = f"https://data.mendeley.com/public-api/datasets/{DATASET_ID}"
CLASSES = {"Organic": "Organic Waste", "Plastic": "Plastic Waste", "Paper": "Paper Waste"}


def session():
    client = requests.Session()
    client.mount("https://", HTTPAdapter(max_retries=Retry(total=4, backoff_factor=1, status_forcelist=[429, 500, 502, 503, 504])))
    return client


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--per-class", type=int, default=100)
    parser.add_argument("--out", type=Path, default=Path("ml/data"))
    parser.add_argument("--seed", type=int, default=42)
    args = parser.parse_args()
    rng = random.Random(args.seed)
    client = session()
    response = client.get(f"{BASE}/folders/1", timeout=60)
    response.raise_for_status()
    selected = []
    for folder in response.json():
        if folder["name"] not in CLASSES:
            continue
        response = client.get(f"{BASE}/files", params={"folder_id": folder["id"], "version": 1, "$limit": 1000}, headers={"Accept": "application/vnd.mendeley-public-dataset.1+json"}, timeout=60)
        response.raise_for_status()
        files = sorted(response.json(), key=lambda item: item["id"])
        for item in rng.sample(files, min(args.per_class, len(files))):
            selected.append((CLASSES[folder["name"]], item))

    def download(entry):
        label, item = entry
        folder = args.out / label
        folder.mkdir(parents=True, exist_ok=True)
        path = folder / f"{item['id']}.jpg"
        details = item["content_details"]
        if not path.exists():
            response = session().get(details["download_url"], timeout=120)
            response.raise_for_status()
            digest = hashlib.sha256(response.content).hexdigest()
            if digest != details["sha256_hash"]:
                raise ValueError(f"Checksum mismatch for {item['id']}")
            with Image.open(io.BytesIO(response.content)) as image:
                image = ImageOps.exif_transpose(image).convert("RGB")
                image.thumbnail((512, 512))
                image.save(path, "JPEG", quality=90)
        return {"id": item["id"], "label": label, "filename": item["filename"], "original_sha256": details["sha256_hash"], "processed_sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "path": path.relative_to(args.out).as_posix(), "download_url": details["download_url"]}

    with ThreadPoolExecutor(max_workers=6) as executor:
        manifest = []
        for entry in executor.map(download, selected):
            manifest.append(entry)
            if len(manifest) % 25 == 0:
                print(f"Downloaded {len(manifest)}/{len(selected)}", flush=True)
    args.out.mkdir(parents=True, exist_ok=True)
    (args.out / "source_manifest.json").write_text(json.dumps({"source": "https://data.mendeley.com/datasets/d4vsy9c9wk/1", "license": "CC BY 4.0", "seed": args.seed, "processing": "EXIF orientation corrected; RGB; max edge 512 px; JPEG quality 90", "images": manifest}, indent=2), encoding="utf-8")
    print(f"Ready: {len(manifest)} images at {args.out}")


if __name__ == "__main__":
    main()
