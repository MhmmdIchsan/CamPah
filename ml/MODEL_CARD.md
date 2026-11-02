# CamPah MobileNetV2

The model predicts one of three labels for a photograph: Organic Waste, Plastic Waste, or Paper Waste. It supplies a category and softmax confidence to the reporting API.

## Data and training

- Source: RealWaste by Single, Iranmanesh, and Raad (2023); see [dataset attribution and licensing](DATASET.md).
- Input: 600 images, 200 per target class. Food Organics and Vegetation are merged into Organic Waste.
- Split: 420 training, 90 validation, 90 test images, stratified with seed 42 after exact duplicate checks.
- Architecture: torchvision MobileNetV2 with ImageNet V2 pretrained weights and a three-output classifier.
- Preprocessing: RGB, 224 × 224 pixels, ImageNet normalization. Training adds flips, rotation, and mild brightness/contrast changes.
- Training: 16 epochs, batch size 16; AdamW at 0.001 for the classifier for five epochs, then 0.0001 with the last three feature blocks unfrozen. BatchNorm statistics remain frozen.
- Checkpoint: epoch 9, selected on validation accuracy **97.78%**. Test data did not select the checkpoint.

## Held out test evaluation

| Metric | Result |
| --- | --- |
| Accuracy | **96.67% (87/90)** |
| Macro precision | 96.97% |
| Macro recall | 96.67% |
| Macro F1 | 96.70% |

Confusion matrix rows are true labels and columns are predictions, in the order Organic Waste, Plastic Waste, Paper Waste:

```text
29   1   0
 0  30   0
 0   2  28
```

The measured accuracy exceeds the assessment's 80% target on this split. The test contains only 90 images from the same source collection; it does not establish performance on every location, camera, or mixed waste scene. Near duplicates or shared capture conditions may remain despite exact duplicate checks. Confidence is the model's softmax score, not a calibrated guarantee of correctness. Photos outside the three material classes still receive one of the three labels.

## Reproduce and use

```sh
python ml/download_dataset.py
python ml/train.py
```

Training writes `ml/artifacts/best_model.pt`, `metrics.json`, `classification_report.txt`, `confusion_matrix.png`, `history.json`, and exact split/source manifests. `environment.json` records the versions used for the submitted run. The checkpoint is included in Git and is loaded by the API; set `MODEL_PATH` to select another checkpoint and restart the API after replacing it.

`ml/examples/` contains three attributed, resized photographs selected from the held out split for integration demos. Their original paths and URLs are recorded in `ml/examples/attribution.json`. The API integration test loads the trained checkpoint and verifies that `/predict`, report creation, and dashboard counts use the same result. These example images are not a separate accuracy benchmark.
