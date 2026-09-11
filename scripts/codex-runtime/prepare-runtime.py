#!/usr/bin/env python3
"""Bundle fixed Codex download manifests and translation catalogs, without binaries."""
import argparse
import json
from pathlib import Path
import shutil
import tempfile


def prepare(output):
    source = Path(__file__).parent
    manifest = json.loads((source / 'runtime-manifest.json').read_text())
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='codex-metadata-', dir=output.parent) as temporary:
        stage = Path(temporary)
        for version in manifest['versions']:
            catalog = source / version / 'translation-models.json'
            models = json.loads(catalog.read_text())['models']
            supported = {'0.134.0': {'gpt-5.5'},
                         '0.153.4': {'gpt-6-astra', 'gpt-5.6-sol', 'gpt-5.6-terra', 'gpt-5.6-luna', 'gpt-5.5'}}
            if {model['slug'] for model in models} != supported[version]:
                raise ValueError('Unexpected ChatGPT model selection in ' + version)
            for model in models:
                if (model['input_modalities'] != ['text'] or model['apply_patch_tool_type'] is not None
                        or model['experimental_supported_tools']):
                    raise ValueError('Unexpected translation capability in ' + version)
                if version == '0.153.4' and (model['tool_mode'] != 'direct' or model['multi_agent_version'] is not None):
                    raise ValueError('Unexpected tool mode')
            (stage / version).mkdir()
            shutil.copyfile(catalog, stage / version / catalog.name)
        shutil.copyfile(source / 'runtime-manifest.json', stage / 'runtime-manifest.json')
        if output.exists():
            shutil.rmtree(output)
        shutil.copytree(stage, output)
    print('Prepared pinned Codex metadata; runtime packages download only when requested')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    prepare(args.output)
