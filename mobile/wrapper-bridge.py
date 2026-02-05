#!/usr/bin/env python3
"""
Wrapper Bridge - Connects mobile UI to shell wrappers
Unique micro-HTTP server for GitUtil mobile interface
"""

import os
import subprocess
import json
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path

BRIDGE_LISTEN_PORT = 8765
SCRIPT_HOME = Path(__file__).parent.absolute()
WRAPPER_STORAGE = SCRIPT_HOME / 'wrappers'

class WrapperBridgeHTTP(BaseHTTPRequestHandler):
    
    def log_message(self, fmt, *arguments):
        pass  # Silent logging
    
    def respond_with_cors(self, status_num, content_dict):
        payload = json.dumps(content_dict).encode('utf-8')
        self.send_response(status_num)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Content-Length', str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)
    
    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()
    
    def do_GET(self):
        if self.path in ['/', '/index', '/index.html']:
            ui_path = SCRIPT_HOME / 'touch-ui.html'
            if ui_path.exists():
                self.send_response(200)
                self.send_header('Content-Type', 'text/html; charset=utf-8')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(ui_path.read_bytes())
            else:
                self.respond_with_cors(404, {'success': False, 'output': 'UI file missing'})
        else:
            self.respond_with_cors(404, {'success': False, 'output': 'Path not found'})
    
    def do_POST(self):
        if self.path == '/exec-wrapper':
            byte_count = int(self.headers.get('Content-Length', 0))
            raw_bytes = self.rfile.read(byte_count)
            
            try:
                parsed_json = json.loads(raw_bytes.decode('utf-8'))
                wrapper_id = parsed_json.get('wrapper', '')
                argument_list = parsed_json.get('args', [])
                
                wrapper_script = WRAPPER_STORAGE / f"{wrapper_id}.sh"
                
                if not wrapper_script.exists():
                    self.respond_with_cors(404, {
                        'success': False,
                        'output': f'Wrapper not found: {wrapper_id}'
                    })
                    return
                
                exec_parts = ['bash', str(wrapper_script)] + argument_list
                
                proc = subprocess.run(
                    exec_parts,
                    capture_output=True,
                    text=True,
                    timeout=30
                )
                
                self.respond_with_cors(200, {
                    'success': True,
                    'output': proc.stdout,
                    'errors': proc.stderr,
                    'exit_code': proc.returncode
                })
                
            except subprocess.TimeoutExpired:
                self.respond_with_cors(500, {
                    'success': False,
                    'output': 'Wrapper execution timeout'
                })
            except Exception as exc:
                self.respond_with_cors(500, {
                    'success': False,
                    'output': f'Error: {str(exc)}'
                })
        else:
            self.respond_with_cors(404, {'success': False, 'output': 'Unknown endpoint'})

def launch_bridge():
    listen_addr = ('localhost', BRIDGE_LISTEN_PORT)
    bridge_instance = HTTPServer(listen_addr, WrapperBridgeHTTP)
    
    print('╔' + '═' * 48 + '╗')
    print('║' + ' ' * 48 + '║')
    print('║  GitUtil Mobile - Wrapper Bridge Active       ║')
    print('║' + ' ' * 48 + '║')
    print('╠' + '═' * 48 + '╣')
    print(f'║  URL: http://localhost:{BRIDGE_LISTEN_PORT}                   ║')
    print(f'║  Wrappers: {str(WRAPPER_STORAGE)[:30]:<30} ║')
    print('║  Press Ctrl+C to terminate                     ║')
    print('╚' + '═' * 48 + '╝')
    
    try:
        bridge_instance.serve_forever()
    except KeyboardInterrupt:
        print('\n[Bridge] Shutting down gracefully...')
        bridge_instance.shutdown()

if __name__ == '__main__':
    import sys
    if len(sys.argv) > 1:
        try:
            BRIDGE_LISTEN_PORT = int(sys.argv[1])
        except ValueError:
            print(f'Invalid port: {sys.argv[1]}')
            sys.exit(1)
    
    launch_bridge()
