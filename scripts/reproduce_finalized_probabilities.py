"""Replay only finalized fits from notebook definitions; never execute search cells.

Run from repository root: .venv/bin/python scripts/reproduce_finalized_probabilities.py
Existing outputs are not overwritten. Source-row positions align to the SHA-256-bound
cleaned CSV; no patient or encounter identifiers are exported.
"""
import ast
import hashlib
import json
import platform
import warnings
from pathlib import Path

import nbformat
import numpy as np
import pandas as pd
import scipy
import sklearn
from joblib import hash as state_hash
from sklearn.base import clone
from sklearn.ensemble import RandomForestClassifier
from sklearn.exceptions import ConvergenceWarning
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (accuracy_score, precision_score, recall_score, f1_score,
                             roc_auc_score, average_precision_score, confusion_matrix)

ROOT = Path(__file__).resolve().parents[1]
NOTEBOOK = ROOT / 'notebooks/04_predictive_modeling.ipynb'
OUTPUT = ROOT / 'data/model_output'


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    assert Path.cwd().resolve() == ROOT, 'Run from the repository root.'
    assert sklearn.__version__ == '1.9.0', 'Stop: original scikit-learn version was 1.9.0.'
    assert not (OUTPUT / 'reproduction_manifest.json').exists(), 'Verified outputs already exist; load them instead.'
    notebook = nbformat.read(NOTEBOOK, as_version=4)
    original_cells = notebook.cells[:58]
    ns = globals()
    # Execute original preparation and the same deterministic first fold, not a new split choice.
    for index in [2, 4, 6, 8, 13, 15]:
        exec(compile(notebook.cells[index].source, f'notebook_cell_{index}', 'exec'), ns)
    assert ns['RANDOM_STATE'] == 42
    assert ns['X_train'].shape == (81_410, 44)
    assert ns['X_evaluation'].shape == (20_353, 44)
    assert len(ns['train_patient_ids']) == 57_175
    assert len(ns['evaluation_patient_ids']) == 14_340
    assert ns['y_evaluation'].sum() == 2_272
    assert ns['train_patient_ids'].isdisjoint(ns['evaluation_patient_ids'])
    # Reuse original guard, pipeline factory and preprocessing audit only.
    # Do not execute CV construction, parameter grids, searches or scoring.
    definitions = ast.parse(notebook.cells[48].source)
    keep = {'CVTrainingGuard', 'make_tuning_pipeline', 'audit_learned_preprocessing'}
    definitions.body = [node for node in definitions.body
                        if isinstance(node, (ast.FunctionDef, ast.ClassDef)) and node.name in keep]
    ns['CV_FIT_AUDIT'] = []
    exec(compile(definitions, 'notebook_pipeline_definitions', 'exec'), ns)
    signature = state_hash(ns['X_train'].index)
    models = {
        'Logistic Regression': LogisticRegression(C=0.1, class_weight=None, solver='liblinear',
                                                  max_iter=2000, random_state=42),
        'Random Forest': RandomForestClassifier(n_estimators=200, max_depth=20, min_samples_leaf=10,
                                                max_features=0.1, class_weight='balanced', random_state=42, n_jobs=2),
    }
    # L2 is the liblinear default in the recorded sklearn version (penalty is deprecated).
    expected = {
        'Logistic Regression': {'counts': [18042, 39, 2241, 31], 'accuracy': .88798,
                               'positive_precision': .44286, 'positive_recall': .01364,
                               'positive_F1': .02647, 'ROC_AUC': .64780, 'average_precision': .19863},
        'Random Forest': {'counts': [13086, 4995, 1182, 1090], 'accuracy': .69651,
                          'positive_precision': .17913, 'positive_recall': .47975,
                          'positive_F1': .26086, 'ROC_AUC': .65140, 'average_precision': .19931},
    }
    results, arrays, parameters = {}, {}, {}
    for name, model in models.items():
        print('Reproducing finalized ' + name, flush=True)
        fitted = ns['make_tuning_pipeline'](model, (signature,))
        with warnings.catch_warnings():
            warnings.simplefilter('error', ConvergenceWarning)
            fitted.fit(ns['X_train'], ns['y_train'])
        assert ns['audit_learned_preprocessing'](fitted).equals(ns['X_train'].index)
        assert np.array_equal(fitted.named_steps['model'].classes_, [0, 1])
        before_prediction = state_hash(fitted)
        probabilities = fitted.predict_proba(ns['X_evaluation'])[:, 1]
        assert state_hash(fitted) == before_prediction
        decisions = probabilities >= .50
        target = ns['y_evaluation']
        metrics = {
            'accuracy': accuracy_score(target, decisions),
            'positive_precision': precision_score(target, decisions, zero_division=0),
            'positive_recall': recall_score(target, decisions),
            'positive_F1': f1_score(target, decisions),
            'ROC_AUC': roc_auc_score(target, probabilities),
            'average_precision': average_precision_score(target, probabilities),
        }
        counts = confusion_matrix(target, decisions, labels=[0, 1]).ravel()
        np.testing.assert_array_equal(counts, expected[name]['counts'])
        for key, value in metrics.items():
            np.testing.assert_allclose(value, expected[name][key], rtol=0, atol=0.0000051,
                                       err_msg=f'Stop: {name} {key} does not reproduce saved result')
        assert probabilities.shape == (20_353,) and np.isfinite(probabilities).all()
        assert ((probabilities >= 0) & (probabilities <= 1)).all()
        results[name] = {'metrics': metrics, 'counts': counts.tolist()}
        arrays[name] = probabilities.copy()
        parameters[name] = model.get_params()
        print(name, results[name], flush=True)
    assert len(ns['CV_FIT_AUDIT']) == 2
    # Persist only after BOTH models pass the reproduction gate.
    OUTPUT.mkdir(parents=True, exist_ok=True)
    files = {}
    for name, stem in [('Logistic Regression', 'tuned_logistic_regression'), ('Random Forest', 'tuned_random_forest')]:
        path = OUTPUT / (stem + '_evaluation_probabilities.npz')
        assert not path.exists()
        np.savez_compressed(path, source_row_position=ns['evaluation_positions'],
                            y_true=ns['y_evaluation'].to_numpy(), probability=arrays[name])
        with np.load(path, allow_pickle=False) as saved:
            np.testing.assert_array_equal(saved['probability'], arrays[name])
        files[name] = {'file': path.name, 'sha256': sha256(path)}
    manifest = {
        'purpose': 'Reproduction of finalized configurations, not new tuning or model selection',
        'source_data': 'data/processed/diabetic_data_cleaned.csv',
        'source_data_sha256': sha256(ns['processed_data_path']),
        'source_cells_sha256': {str(i): hashlib.sha256(notebook.cells[i].source.encode()).hexdigest()
                                for i in [2, 4, 6, 8, 13, 15, 48]},
        'versions': {'python': platform.python_version(), 'numpy': np.__version__, 'pandas': pd.__version__,
                     'scipy': scipy.__version__, 'scikit_learn': sklearn.__version__},
        'split': {'method': 'Original first fold of StratifiedGroupKFold(n_splits=5, shuffle=True, random_state=42)',
                  'train_rows': 81410, 'evaluation_rows': 20353, 'train_patients': 57175,
                  'evaluation_patients': 14340, 'patient_overlap': 0,
                  'train_positions_hash': state_hash(ns['train_positions']),
                  'evaluation_positions_hash': state_hash(ns['evaluation_positions'])},
        'predictors': ns['selected_features'], 'exclusions': ns['exclusion_reasons'],
        'parameters': parameters, 'validation': results, 'expected_saved_results': expected,
        'metric_absolute_tolerance': 0.0000051, 'confusion_counts_exact': True,
        'reproduction_fit_count': 2, 'search_fit_count': 0, 'prediction_calls_per_model': 1,
        'files': files,
        'alignment': 'Zero-based source CSV data-row position; file order is original evaluation order. No patient identifiers.',
    }
    (OUTPUT / 'reproduction_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    assert nbformat.read(NOTEBOOK, 4).cells[:58] == original_cells
    print('PASS: both finalized models reproduce saved results; probabilities persisted losslessly.', flush=True)


if __name__ == '__main__':
    main()
