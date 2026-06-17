import json
import os

log_path = r"C:\Users\14749\.gemini\antigravity\brain\d8a5c1f8-45fc-468f-aeff-d49af7285ac8\.system_generated\logs\transcript_full.jsonl"
with open(log_path, 'r', encoding='utf-8') as f:
    for line in f:
        try:
            data = json.loads(line)
            if data.get('step_index') == 109 and data.get('type') == 'TOOL_RESPONSE':
                output = data.get('content', '')
                with open(r"d:\workspace\bounty-do\gamified_todo\lib\main.dart", 'w', encoding='utf-8') as mf:
                    mf.write(output)
                print("main.dart restored!")
                break
        except Exception as e:
            pass