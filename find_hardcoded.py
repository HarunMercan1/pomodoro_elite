import os
import re

lib_dir = r"c:\my-projects\pomodoro_elite\lib"

def check_files():
    found_any = False
    with open('hardcoded_strings.txt', 'w', encoding='utf-8') as out:
        for root, dirs, files in os.walk(lib_dir):
            for file in files:
                if file.endswith(".dart"):
                    path = os.path.join(root, file)
                    with open(path, "r", encoding="utf-8") as f:
                        content = f.read()
                        lines = content.split('\n')
                        for i, line in enumerate(lines):
                            if line.strip().startswith('//'):
                                continue
                            
                            # Search for any string literal with Turkish chars
                            matches = re.findall(r'[\'"]([^\'"]*[ğüşöçıĞÜŞÖÇİ][^\'"]*)[\'"]', line)
                            for match in matches:
                                if not ".tr()" in line:
                                    out.write(f"{file}:{i+1}: {match}\n")
                                    found_any = True

        if not found_any:
            out.write("No hardcoded Turkish strings found.\n")

check_files()
