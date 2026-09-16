#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
python3 - "$ROOT_DIR" <<'PY'
import pathlib,re,sys
root=pathlib.Path(sys.argv[1]); failures=[]
for md in root.rglob("*.md"):
    text=md.read_text(encoding="utf-8")
    for target in re.findall(r"\[[^]]+\]\(([^)]+)\)",text):
        if "://" in target or target.startswith("#"): continue
        path=(md.parent/target.split("#",1)[0]).resolve()
        if not path.exists(): failures.append(f"{md.relative_to(root)} -> {target}")
if failures:
    raise SystemExit("Broken local links:\n"+"\n".join(failures))
print("PASS local Markdown links")
PY
