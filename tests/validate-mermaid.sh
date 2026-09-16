#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
python3 - "$ROOT_DIR" <<'PY'
import pathlib,re,sys
root=pathlib.Path(sys.argv[1]); count=0; failures=[]
allowed=("flowchart ","sequenceDiagram","stateDiagram","classDiagram","erDiagram","timeline","journey","mindmap")
for md in root.rglob("*.md"):
    text=md.read_text(encoding="utf-8")
    opens=len(re.findall(r"^```mermaid\s*$",text,re.M))
    blocks=re.findall(r"^```mermaid\s*\n(.*?)^```\s*$",text,re.M|re.S)
    if opens != len(blocks): failures.append(f"unclosed Mermaid fence: {md.relative_to(root)}")
    for block in blocks:
        count+=1
        first=next((line.strip() for line in block.splitlines() if line.strip()),"")
        if not first.startswith(allowed): failures.append(f"unsupported/empty Mermaid block in {md.relative_to(root)}: {first}")
if failures: raise SystemExit("\n".join(failures))
if count == 0: raise SystemExit("No Mermaid diagrams found")
print(f"PASS structural Mermaid checks ({count} diagrams); renderer validation requires mmdc")
PY
