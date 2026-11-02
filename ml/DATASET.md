# Dataset

Source: [Automatic waste management dataset](https://data.mendeley.com/datasets/d4vsy9c9wk/1), Mendeley Data, DOI `10.17632/d4vsy9c9wk.1`, licensed CC BY 4.0. Credit: Abdun Nafi Annafi, Tasnuva Muhtasim, Sheikh Kaif, Tahmeed Mohammad Farhan, Aynun Naher Mou, and Mayen Uddin Mojumdar (2025).

Run `python ml/download_dataset.py --per-class 100` from the repository root. It selects a deterministic subset of each class, verifies original SHA-256 checksums, resizes images to a maximum edge of 512 pixels, and records original filenames, URLs, checksums, and modifications in `ml/data/source_manifest.json`. Files are placed in `ml/data/Organic Waste`, `ml/data/Plastic Waste`, and `ml/data/Paper Waste`. Keep at least 50 unique images per class. The training script records exact counts and train/validation/test file paths in `ml/artifacts/split_manifest.json`. The downloaded dataset is excluded from Git due to size; include the downloadable archive and this source link in the submission.

Run from repository root: `python ml/train.py --data ml/data --out ml/artifacts`. The script checks image validity and exact duplicates before a stratified 70/15/15 split. Only the training split receives augmentation. Report the real test accuracy; the 80% target is not a guaranteed result.
