# RealWaste dataset for CamPah

Source: [RealWaste, UCI Machine Learning Repository](https://archive.ics.uci.edu/dataset/908/realwaste). Authors: Sam Single, Saeid Iranmanesh, and Raad Raad (2023). Paper: *RealWaste: A Novel Real-Life Data Set for Landfill Waste Classification Using Deep Learning*, Information 14(12), 633, https://doi.org/10.3390/info14120633.

Files come from the [authors' repository](https://github.com/sam-single/realwaste). UCI lists CC BY 4.0; the authors' repository lists **CC BY-NC-SA 4.0**. This assessment uses the files for noncommercial purposes and retains attribution and the authors' more restrictive license notice. Resized dataset derivatives retain the same notice. The discrepancy is documented rather than assuming unrestricted commercial use.

## Class mapping

| Source folders | CamPah label |
| --- | --- |
| Food Organics, Vegetation | Organic Waste |
| Plastic | Plastic Waste |
| Paper | Paper Waste |

Run `python ml/download_dataset.py` from the repository root. It selects 200 images per target class (600 total), with seed 42 and a pinned source Git commit. The script verifies source Git blob checksums, corrects EXIF orientation, converts images to RGB, and resizes the longest edge to at most 512 pixels. Source URLs, filenames, checksums, modifications, and the exact selection are preserved in `ml/data/realwaste/source_manifest.json` and `selection.json`. Rerun the same command to resume an interrupted download.

Fresh downloads default to the revision recorded in the committed `ml/artifacts/source_manifest.json`, so later changes in the upstream repository do not silently change the submitted dataset. To deliberately select another upstream revision, pass `--revision COMMIT_SHA` and use a separate output directory.

Train with `python ml/train.py --data ml/data/realwaste --out ml/artifacts`. Splits are stratified 70/15/15 after removing exact duplicates; augmentation is applied only to training data. Checkpoint selection uses validation accuracy. The held out test split is used only for final evaluation. Report the measured accuracy even if below the 80% target. Mixed or unsupported materials and different camera environments remain limitations of a three-class model.

## Change from the initial PRD

The initially selected Mendeley dataset (`10.17632/d4vsy9c9wk.1`) exposed only two files in its Plastic folder, both HEIC, when checked on 2 November 2026. That does not meet the minimum 50 images per class required by the training pipeline. RealWaste replaces that source for all three classes to avoid combining class labels with different source domains. Partial Mendeley downloads are excluded from the RealWaste training input.
