#!/usr/bin/env python3
"""Run the official executable against a loopback-only Responses fixture.

Input JSON is emitted from CodexManagedRuntime.translationArguments and contains
executable, arguments and cwd. No real login, credentials or model is used.
"""
import argparse
import http.server
import json
import re
from pathlib import Path
import struct
import subprocess
import tempfile
import threading
import zlib


def png():
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', 1, 1, 8, 2, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(b'\0\xff\0\0')) + chunk(b'IEND', b''))


def normalized_context(items, prompt):
    def strip_ids(value):
        if isinstance(value, dict):
            return {k: strip_ids(v) for k, v in value.items() if k != 'id'}
        if isinstance(value, list):
            return [strip_ids(v) for v in value]
        return value
    context = json.dumps(strip_ids(items), sort_keys=True).replace(prompt, '<PROMPT>')
    return re.sub(r'/tmp/arg0/codex-arg0[A-Za-z0-9]+', '/tmp/arg0/<INSTANCE>', context)


def verify(config):
    # Codex declines helper setup inside temporary CODEX_HOME. This dedicated
    # fixture directory is still disposable and never shares an auth namespace.
    root = Path.home() / 'Library/Application Support/Easydict-Codex-Gate0'
    root.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='isolation-', dir=root) as temporary:
        home = Path(temporary)
        state = home / 'state'
        state.mkdir()
        canary = home / 'canary.png'
        canary.write_bytes(png())
        link = home / 'linked-canary.png'
        link.symlink_to(canary)
        target = home / 'forbidden-write'
        cases = [
            ('image', {'type': 'function_call', 'name': 'view_image',
                       'arguments': json.dumps({'path': str(canary)})}, ('not allowed', 'unsupported')),
            ('image-symlink', {'type': 'function_call', 'name': 'view_image',
                               'arguments': json.dumps({'path': str(link)})}, ('not allowed', 'unsupported')),
            ('write', {'type': 'custom_tool_call', 'name': 'apply_patch',
                       'input': f'*** Begin Patch\n*** Add File: {target}\n+CANARY\n*** End Patch'},
             'unsupported custom tool call'),
            ('shell', {'type': 'function_call', 'name': 'exec_command',
                       'arguments': json.dumps({'cmd': f'touch {target}'})}, 'unsupported'),
        ]
        if any('0.153.4' in arg for arg in config['arguments']):
            cases += [
                ('agent', {'type': 'function_call', 'name': 'collaboration.spawn_agent',
                           'arguments': json.dumps({'task_name': 'forbidden', 'message': 'Hello'})}, 'unsupported'),
                ('plan', {'type': 'function_call', 'name': 'update_plan',
                          'arguments': json.dumps({'plan': []})}, 'unsupported'),
                ('input', {'type': 'function_call', 'name': 'request_user_input',
                           'arguments': json.dumps({'questions': []})}, 'unsupported'),
            ]
        for name, tool, rejection in cases:
            captured = []

            class Handler(http.server.BaseHTTPRequestHandler):
                def log_message(self, *_):
                    pass

                def do_POST(self):
                    captured.append(json.loads(self.rfile.read(int(self.headers['Content-Length']))))
                    item = ({**tool, 'id': 'tool1', 'call_id': 'call1'} if len(captured) == 1 else
                            {'type': 'message', 'role': 'assistant', 'id': 'message1',
                             'content': [{'type': 'output_text', 'text': '你好'}]})
                    events = [
                        {'type': 'response.created', 'response': {'id': 'response1'}},
                        {'type': 'response.output_item.done', 'item': item},
                        {'type': 'response.completed', 'response': {'id': 'response1', 'status': 'completed',
                         'output': [], 'usage': {'input_tokens': 1, 'output_tokens': 1, 'total_tokens': 2}}},
                    ]
                    data = ''.join('event: ' + e['type'] + '\ndata: ' + json.dumps(e) + '\n\n' for e in events).encode()
                    self.send_response(200)
                    self.send_header('Content-Type', 'text/event-stream')
                    self.send_header('Content-Length', str(len(data)))
                    self.end_headers()
                    self.wfile.write(data)

            server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), Handler)
            thread = threading.Thread(target=server.serve_forever, daemon=True)
            thread.start()
            overrides = {
                'model_provider': 'easydict-test',
                'model_providers.easydict-test.name': 'Loopback fixture',
                'model_providers.easydict-test.base_url': f'http://127.0.0.1:{server.server_port}/v1',
                'model_providers.easydict-test.wire_api': 'responses',
                'model_providers.easydict-test.requires_openai_auth': False,
                'cli_auth_credentials_store': 'keyring',
            }
            arguments = list(config['arguments'])
            for key, value in overrides.items():
                arguments += ['-c', key + '=' + json.dumps(value)]
            environment = {'HOME': str(Path.home()), 'CODEX_HOME': str(state),
                           'PATH': '/usr/bin:/bin:/usr/sbin:/sbin', 'LANG': 'en_US.UTF-8', 'NO_PROXY': '127.0.0.1'}
            try:
                baseline = subprocess.run([config['executable'], *arguments, '--', '-'],
                                          input='Translate literally: Hello',
                                          env=environment, cwd=config['cwd'], capture_output=True, text=True, timeout=40)
                assert baseline.returncode == 0 and len(captured) == 2, (name, 'baseline failed')
                baseline_request = normalized_context(captured[0]['input'], 'Translate literally: Hello')
                captured.clear()
                result = subprocess.run([config['executable'], *arguments, '--', '-'],
                                        input='Translate literally: $skill-creator $skill-installer',
                                        env=environment, cwd=config['cwd'], capture_output=True, text=True, timeout=40)
            finally:
                server.shutdown()
                server.server_close()
                thread.join()
            assert result.returncode == 0, (name, result.returncode, result.stderr[-1000:])
            assert len(captured) == 2, (name, len(captured))
            serialized = json.dumps(captured)
            assert 'data:image/' not in serialized, name + ': image escaped'
            actual_request = normalized_context(captured[0]['input'], 'Translate literally: $skill-creator $skill-installer')
            assert actual_request == baseline_request, name + ': skill changed request context'
            assert not target.exists(), name + ': file was written'
            outputs = [i for i in captured[-1]['input'] if i.get('type', '').endswith('call_output')]
            rejections = rejection if isinstance(rejection, tuple) else (rejection,)
            assert any(text in json.dumps(i) for i in outputs for text in rejections), (name, outputs)
            print('PASS', name)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('arguments_json', type=Path)
    args = parser.parse_args()
    verify(json.loads(args.arguments_json.read_text()))
