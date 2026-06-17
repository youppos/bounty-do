import json
import re
import os

files_state = {}
last_viewed_file = None

logs = [
    r"C:\Users\14749\.gemini\antigravity\brain\d8a5c1f8-45fc-468f-aeff-d49af7285ac8\.system_generated\logs\transcript_full.jsonl",
    r"C:\Users\14749\.gemini\antigravity\brain\6845116a-0a10-4c34-9308-c706414d1a1a\.system_generated\logs\transcript_full.jsonl"
]

def apply_replace(content, start_line, end_line, target, replacement):
    if content == '':
        return ''
    lines = content.split('\n')
    start_idx = start_line - 1
    end_idx = end_line
    content_str = '\n'.join(lines)
    return content_str.replace(target, replacement)

def extract_view_content(content):
    # content looks like:
    # Created At: ...\nCompleted At: ...\nFile Path: ...\nTotal Lines: ...\nTotal Bytes: ...\nShowing lines 1 to ...\nThe following code has been modified to include a line number before every line...
    # 1: import ...
    lines = content.split('\n')
    extracted = []
    start_parsing = False
    for line in lines:
        if line.startswith('1: '):
            start_parsing = True
        
        if start_parsing:
            if re.match(r'^\d+: ', line):
                extracted.append(re.sub(r'^\d+: ', '', line))
            elif line.startswith('The above content shows the entire, complete file contents'):
                break
    return '\n'.join(extracted)

for log_path in logs:
    if not os.path.exists(log_path): continue
    with open(log_path, 'r', encoding='utf-8') as f:
        for line in f:
            try:
                data = json.loads(line)
                
                # capture view_file command
                if 'tool_calls' in data:
                    for tc in data['tool_calls']:
                        if tc['name'] == 'view_file':
                            path = tc['args'].get('AbsolutePath', '').replace('/', '\\').lower()
                            if 'gamified_todo\\lib' in path:
                                last_viewed_file = path
                                
                        if tc['name'] == 'write_to_file':
                            path = tc['args'].get('TargetFile', '').replace('/', '\\').lower()
                            if 'gamified_todo\\lib' in path:
                                files_state[path] = tc['args'].get('CodeContent', '')
                        elif tc['name'] == 'replace_file_content':
                            path = tc['args'].get('TargetFile', '').replace('/', '\\').lower()
                            if path in files_state and files_state[path] != '':
                                args = tc['args']
                                files_state[path] = apply_replace(files_state[path], args['StartLine'], args['EndLine'], args['TargetContent'], args['ReplacementContent'])
                        elif tc['name'] == 'multi_replace_file_content':
                            path = tc['args'].get('TargetFile', '').replace('/', '\\').lower()
                            if path in files_state and files_state[path] != '':
                                chunks = tc['args'].get('ReplacementChunks', [])
                                for chunk in chunks:
                                    files_state[path] = apply_replace(files_state[path], chunk['StartLine'], chunk['EndLine'], chunk['TargetContent'], chunk['ReplacementContent'])
                
                # capture view_file response
                if data.get('type') == 'VIEW_FILE' and last_viewed_file:
                    if last_viewed_file not in files_state or files_state[last_viewed_file] == '':
                        content = extract_view_content(data.get('content', ''))
                        if content:
                            files_state[last_viewed_file] = content
                    last_viewed_file = None
            except:
                pass

for k, v in files_state.items():
    if v != '':
        os.makedirs(os.path.dirname(k), exist_ok=True)
        with open(k, 'w', encoding='utf-8') as f:
            f.write(v)
        print(f"Restored {k}")