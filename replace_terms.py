import os
import re

replacements = [
    (r'\bgorgées\b', 'pénalités'),
    (r'\bgorgée\b', 'pénalité'),
    (r'\bGorgées\b', 'Pénalités'),
    (r'\bGorgée\b', 'Pénalité'),
    (r'\bboit\b', 'prend'),
    (r'\bBoit\b', 'Prend'),
    (r'\bboire\b', 'prendre'),
    (r'\bBoire\b', 'Prendre'),
    (r'\bcul sec\b', 'gage fatal'),
    (r'\bCul sec\b', 'Gage fatal'),
    (r'\bCul Sec\b', 'Gage Fatal'),
]

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    for pattern, repl in replacements:
        new_content = re.sub(pattern, repl, new_content)
        
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
