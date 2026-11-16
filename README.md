# agent-voice

Local speech-to-text and text-to-speech for Claude Code and pi. The models run on the Linux box's RTX 4060; the agents can be used at the Linux desktop or from the Mac over SSH.

| | At the Linux desktop | From the Mac over SSH |
|---|---|---|
| Dictate | voxtype: hold **F9** or toggle **Super+Ctrl+X** | Hammerspoon: hold **⌥Space** |
| Replies spoken | `pw-play` on Linux speakers | `afplay` on the Mac (auto when `SSH_CONNECTION` is set) |

Both directions go through one server, [Speaches](https://github.com/speaches-ai/speaches), in Docker on the GPU, bound to `127.0.0.1:8000`: Whisper `large-v3-turbo` for STT and Kokoro (voice `ef_dora`) for TTS.

## Layout

- `speaches/run.sh`: (re)creates the container and loads both models.
- `bin/agent-speak`: TTS for agent replies. Strips code, caps at ~600 chars, plays locally or on the Mac.
- `pi/agent-speak.ts`: pi extension that speaks the final reply. `pi/stt.json` configures pi-voice-stt (Ctrl+R records on the Linux mic).
- `voxtype/config.toml`: voxtype in remote mode against Speaches, Spanish and English.
- `mac/init.lua`: Hammerspoon hold-to-talk for the Mac.

## Install

Linux:

```bash
./install-linux.sh             # link files, add Claude hooks, restart voxtype
./install-linux.sh --speaches  # same, plus recreate the Speaches container
```

Mac:

```bash
git clone yulpher-dev:Documents/agent-voice ~/agent-voice
~/agent-voice/mac/install.sh
```

Then give Hammerspoon **Accessibility** and **Microphone** permissions. To update the Mac, run `git pull` in `~/agent-voice` and reload the Hammerspoon config.

## Everyday use

- Mute TTS: `touch ~/.cache/agent-speak.off` (rm to unmute). Stop playback: `agent-speak --stop`, or send a new message.
- Another voice: set `AGENT_SPEAK_VOICE` (e.g. `em_alex`).
- If you SSH in from a machine other than the Mac, set `AGENT_SPEAK_SSH` to its ssh alias.
- Inside tmux, `SSH_CONNECTION` is whatever it was when the tmux server started, so audio can go to the wrong machine.
