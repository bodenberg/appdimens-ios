#!/usr/bin/env python3
"""Validate local Markdown links, skill metadata, and the source-only policy."""
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
errors: list[str] = []
markdown = [ROOT / "README.md", ROOT / "GUIDE-FOR-BEGINNERS.md"]
markdown += list((ROOT / "Documentation").rglob("*.md"))
markdown += list((ROOT / "skills").rglob("*.md"))

link_pattern = re.compile(r"\[[^]]*\]\(([^)]+)\)")
for document in markdown:
    if not document.exists():
        continue
    for target in link_pattern.findall(document.read_text(encoding="utf-8")):
        if target.startswith(("http://", "https://", "mailto:", "#")):
            continue
        path = target.split("#", 1)[0]
        if path and not (document.parent / path).resolve().exists():
            errors.append(f"{document.relative_to(ROOT)}: broken link {target}")

skill = ROOT / "skills/appdimens-ios/SKILL.md"
if not skill.exists():
    errors.append("skills/appdimens-ios/SKILL.md is missing")
else:
    text = skill.read_text(encoding="utf-8")
    if not re.match(r"^---\nname: appdimens-ios\ndescription: .+\n---\n", text):
        errors.append("AppDimens skill has invalid YAML frontmatter")

tracked = subprocess.check_output(
    ["git", "ls-files", "-z"], cwd=ROOT
).split(b"\0")
for raw_name in tracked:
    if not raw_name:
        continue
    path = ROOT / raw_name.decode("utf-8")
    if not path.is_file():
        continue
    data = path.read_bytes()
    if b"\0" in data:
        errors.append(f"{path.relative_to(ROOT)}: binary/NUL content is not allowed")
    try:
        data.decode("utf-8")
    except UnicodeDecodeError:
        errors.append(f"{path.relative_to(ROOT)}: content is not UTF-8")

if errors:
    print("\n".join(f"ERROR: {error}" for error in errors))
    sys.exit(1)
print(f"Validated {len(markdown)} Markdown files and {len(tracked) - 1} tracked files.")
