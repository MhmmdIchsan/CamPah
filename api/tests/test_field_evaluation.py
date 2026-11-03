import importlib.util
from pathlib import Path
import pytest

spec = importlib.util.spec_from_file_location('evaluate_field', Path(__file__).resolve().parents[2] / 'ml' / 'evaluate_field.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def test_field_evaluation_separates_test_and_rejects_duplicate_photos(tmp_path):
    (tmp_path / 'one.jpg').write_bytes(b'one')
    (tmp_path / 'two.jpg').write_bytes(b'two')
    manifest = tmp_path / 'manifest.csv'
    manifest.write_text('path,label,split\none.jpg,Plastic Waste,validation\ntwo.jpg,Other,test\n', encoding='utf-8')
    result = module.evaluate(manifest, lambda data: ('Plastic Waste', .9))
    assert result['validation']['accuracy'] == 1
    assert result['test']['outside_count'] == 1
    assert result['test']['accuracy'] is None
    manifest.write_text('path,label,split\none.jpg,Plastic Waste,validation\none.jpg,Other,test\n', encoding='utf-8')
    with pytest.raises(ValueError, match='identik'):
        module.evaluate(manifest, lambda data: ('Plastic Waste', .9))
