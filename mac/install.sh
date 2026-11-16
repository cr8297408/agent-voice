#!/usr/bin/env bash
# Run on the Mac from the cloned repo: installs Hammerspoon and links mac/init.lua as its config.
set -euo pipefail
REPO=$(cd "$(dirname "$0")/.." && pwd)
export PATH=/opt/homebrew/bin:$PATH

[ -d /Applications/Hammerspoon.app ] || brew install --cask hammerspoon
command -v ffmpeg >/dev/null || brew install ffmpeg

mkdir -p "$HOME/.hammerspoon"
target="$HOME/.hammerspoon/init.lua"
if [ -e "$target" ] && [ ! -L "$target" ]; then mv "$target" "$target.bak"; echo "backed up $target -> $target.bak"; fi
ln -sfn "$REPO/mac/init.lua" "$target"
echo "linked $target"

ssh -o BatchMode=yes -o ConnectTimeout=5 yulpher-dev 'curl -sf http://127.0.0.1:8000/health >/dev/null' \
  && echo "Speaches reachable through yulpher-dev" \
  || echo "WARNING: cannot reach Speaches via 'ssh yulpher-dev' — is the container running?"

open -a Hammerspoon
cat <<'MSG'
Grant Hammerspoon two permissions in System Settings → Privacy & Security:
  - Accessibility (to type the transcript)
  - Microphone (asked the first time you hold ⌥Space)
Then Hammerspoon menu bar icon → Reload Config.
MSG
