"""Download a reproducible RealWaste subset from the authors' repository."""
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import hashlib
import io
import json
from pathlib import Path
import random
import time
from urllib.parse import quote

from PIL import Image, ImageOps
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

REPOSITORY = "sam-single/realwaste"
SOURCE = "https://archive.ics.uci.edu/dataset/908/realwaste"
CLASS_MAP = {"Food Organics": "Organic Waste", "Vegetation": "Organic Waste", "Plastic": "Plastic Waste", "Paper": "Paper Waste"}


def session():
    client = requests.Session()
    client.mount("https://", HTTPAdapter(max_retries=Retry(total=3, backoff_factor=1, status_forcelist=[429, 500, 502, 503, 504])))
    return client


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--per-class", type=int, default=200)
    parser.add_argument("--out", type=Path, default=Path("ml/data/realwaste"))
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--workers", type=int, default=6)
    parser.add_argument("--revision", help="Override the source revision pinned by the submitted manifest")
    args = parser.parse_args()
    if args.per_class < 50 or args.workers < 1:
        parser.error("Use at least 50 images per class and at least 1 worker")
    args.out.mkdir(parents=True, exist_ok=True)
    selection_path = args.out / "selection.json"
    with session() as client:
        if selection_path.exists():
            selection = json.loads(selection_path.read_text(encoding="utf-8"))
            if selection["seed"] != args.seed or selection["per_class"] != args.per_class:
                raise SystemExit("Existing selection differs. Use a new --out directory to keep dataset versions separate.")
            commit, selected = selection["commit"], selection["files"]
            if args.revision and args.revision != commit:
                raise SystemExit("Existing selection uses a different revision. Use a new --out directory.")
        else:
            submitted_manifest = Path(__file__).resolve().parent / "artifacts" / "source_manifest.json"
            submitted = json.loads(submitted_manifest.read_text(encoding="utf-8")) if submitted_manifest.exists() else {}
            revision = args.revision or submitted.get("commit", "main")
            response = client.get(f"https://api.github.com/repos/{REPOSITORY}/commits/{revision}", timeout=45)
            response.raise_for_status()
            commit = response.json()["sha"]
            response = client.get(f"https://api.github.com/repos/{REPOSITORY}/git/trees/{commit}", params={"recursive": 1}, timeout=45)
            response.raise_for_status()
            if response.json().get("truncated"):
                raise SystemExit("Repository listing was truncated")
            grouped = {label: [] for label in sorted(set(CLASS_MAP.values()))}
            for item in response.json()["tree"]:
                parts = item["path"].split("/")
                if len(parts) == 3 and parts[0] == "RealWaste" and parts[1] in CLASS_MAP and parts[2].lower().endswith(".jpg"):
                    grouped[CLASS_MAP[parts[1]]].append(item)
            rng = random.Random(args.seed)
            selected = []
            for label, files in grouped.items():
                if len(files) < args.per_class:
                    raise SystemExit(f"Only {len(files)} images available for {label}")
                selected.extend({**item, "label": label} for item in rng.sample(sorted(files, key=lambda item: item["path"]), args.per_class))
            selection_path.write_text(json.dumps({"commit": commit, "seed": args.seed, "per_class": args.per_class, "files": selected}, indent=2), encoding="utf-8")

    def download(item):
        source_path = item["path"]
        path = args.out / item["label"] / Path(source_path).name
        path.parent.mkdir(parents=True, exist_ok=True)
        url = f"https://raw.githubusercontent.com/{REPOSITORY}/{commit}/{quote(source_path)}"
        if path.exists():
            with Image.open(path) as image:
                image.verify()
        else:
            for attempt in range(3):
                try:
                    with session() as downloader:
                        response = downloader.get(url, timeout=(15, 45))
                        response.raise_for_status()
                    break
                except requests.RequestException:
                    if attempt == 2:
                        raise
                    time.sleep(2 ** attempt)
            content = response.content
            digest = hashlib.sha1(f"blob {len(content)}\0".encode() + content).hexdigest()
            if digest != item["sha"]:
                raise ValueError(f"Source checksum mismatch: {source_path}")
            with Image.open(io.BytesIO(content)) as image:
                image = ImageOps.exif_transpose(image).convert("RGB")
                image.thumbnail((512, 512))
                temporary = path.with_suffix(".part")
                image.save(temporary, "JPEG", quality=90)
                temporary.replace(path)
        return {"label": item["label"], "original_path": source_path, "original_git_sha1": item["sha"], "processed_sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "path": path.relative_to(args.out).as_posix(), "download_url": url}

    manifest, failures = [], []
    def checkpoint():
        document = {"source": SOURCE, "repository": f"https://github.com/{REPOSITORY}", "commit": commit, "license": "CC BY-NC-SA 4.0 (authors repository); UCI lists CC BY 4.0", "seed": args.seed, "requested_per_class": args.per_class, "complete": len(manifest) == len(selected), "processing": "EXIF orientation corrected; RGB; max edge 512 px; JPEG quality 90", "images": sorted(manifest, key=lambda entry: entry["path"]), "failed_paths": failures}
        temporary = args.out / "source_manifest.json.tmp"
        temporary.write_text(json.dumps(document, indent=2), encoding="utf-8")
        temporary.replace(args.out / "source_manifest.json")
    with ThreadPoolExecutor(max_workers=args.workers) as executor:
        futures = {executor.submit(download, item): item for item in selected}
        for future in as_completed(futures):
            try:
                manifest.append(future.result())
            except Exception as error:
                failures.append(futures[future]["path"])
                print(f"Failed {futures[future]['path']}: {type(error).__name__}; rerun to retry", flush=True)
            checkpoint()
            if (len(manifest) + len(failures)) % 25 == 0:
                print(f"Downloaded {len(manifest)}/{len(selected)}, failed {len(failures)}", flush=True)
    checkpoint()
    if failures:
        raise SystemExit(f"{len(failures)} downloads failed; completed images are preserved. Rerun the same command.")
    print(f"Ready: {len(manifest)} images at {args.out}")


if __name__ == "__main__":
    main()
