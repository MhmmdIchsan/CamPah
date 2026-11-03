"""Evaluate labelled field photos with separate validation and test sets.

CSV columns: path,label,split. Labels: Organic Waste, Plastic Waste, Paper Waste,
Other, Mixed. Paths are relative to the CSV. Photos must not appear in both splits.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'api'))
from app.predictor import LABELS, predict

OUTSIDE = ('Other', 'Mixed')


def evaluate(manifest, predictor=predict):
    manifest = Path(manifest)
    with manifest.open(encoding='utf-8-sig', newline='') as stream:
        rows = list(csv.DictReader(stream))
    if not rows:
        raise ValueError('Manifest kosong')
    items = []
    hashes = {}
    for row in rows:
        label, split = row.get('label', ''), row.get('split', '')
        if label not in (*LABELS, *OUTSIDE) or split not in ('validation', 'test'):
            raise ValueError('Label atau split tidak valid')
        path = (manifest.parent / row['path']).resolve()
        data = path.read_bytes()
        digest = hashlib.sha256(data).hexdigest()
        if digest in hashes:
            raise ValueError('Foto identik ditemukan lebih dari sekali: ' + row['path'])
        hashes[digest] = split
        result = predictor(data)
        if result is None:
            raise ValueError('Model tidak tersedia')
        items.append({'label': label, 'split': split, 'prediction': result[0], 'confidence': float(result[1])})
    validation = [x for x in items if x['split'] == 'validation']
    test = [x for x in items if x['split'] == 'test']
    if not validation or not test:
        raise ValueError('Kedua split validation dan test wajib tersedia')

    def summarize(group):
        in_class = [x for x in group if x['label'] in LABELS]
        outside = [x for x in group if x['label'] in OUTSIDE]
        return {'count': len(group), 'in_class_count': len(in_class),
                'accuracy': sum(x['prediction'] == x['label'] for x in in_class) / len(in_class) if in_class else None,
                'by_class': {label: {'count': sum(x['label'] == label for x in group),
                                     'correct': sum(x['label'] == label and x['prediction'] == label for x in group)} for label in LABELS},
                'outside_count': len(outside),
                'outside_mean_confidence': sum(x['confidence'] for x in outside) / len(outside) if outside else None}

    return {'validation': summarize(validation), 'test': summarize(test), 'predictions': items,
            'note': 'Confidence softmax bukan probabilitas terkalibrasi; model selalu memilih salah satu dari tiga kelas. Tidak ada ambang otomatis yang ditetapkan.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('manifest', help='CSV path,label,split')
    parser.add_argument('--output', required=True, help='Path JSON hasil evaluasi')
    args = parser.parse_args()
    result = evaluate(args.manifest)
    Path(args.output).write_text(json.dumps(result, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    print(f"Evaluasi selesai: {result['validation']['count']} validation, {result['test']['count']} test")


if __name__ == '__main__':
    main()
