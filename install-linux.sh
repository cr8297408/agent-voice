#!/usr/bin/env bash
# Link this repo's files into place on the Linux box and register the Claude Code hooks.
# Idempotent: re-run after pulling changes. Existing real files are moved to *.bak once.
# Pass --speaches to also (re)create the Speaches container.
set -euo pipefail
REPO=$(cd "$(dirname "$0")" && pwd)

link() { # link <repo file> <target>
  mkdir -p "$(dirname "$2")"
  if [ -e "$2" ] && [ ! -L "$2" ]; then mv "$2" "$2.bak"; echo "backed up $2 -> $2.bak"; fi
  ln -sfn "$REPO/$1" "$2"
  echo "linked $2"
}

link bin/agent-speak       "$HOME/.local/bin/agent-speak"
link pi/agent-speak.ts     "$HOME/.pi/agent/extensions/agent-speak.ts"
link pi/stt.json           "$HOME/.pi/agent/stt.json"
link voxtype/config.toml   "$HOME/.config/voxtype/config.toml"

# Claude Code: settings.json holds unrelated config, so merge the two hooks instead of linking.
python3 -I - "$HOME/.claude/settings.json" <<'EOF'
import json, sys
path = sys.argv[1]
settings = json.load(open(path))
hooks = settings.setdefault("hooks", {})
for event, cmd in [("Stop", "$HOME/.local/bin/agent-speak --claude-hook"),
                   ("UserPromptSubmit", "$HOME/.local/bin/agent-speak --stop")]:
    entries = hooks.setdefault(event, [])
    if not any(h.get("command") == cmd for e in entries for h in e.get("hooks", [])):
        entries.append({"hooks": [{"type": "command", "command": cmd, "timeout": 10}]})
        print(f"added Claude {event} hook")
with open(path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")
EOF

systemctl --user restart voxtype && echo "restarted voxtype"
[ "${1:-}" = "--speaches" ] && "$REPO/speaches/run.sh"
echo "done. Restart Claude Code and pi to load the hooks/extension."
