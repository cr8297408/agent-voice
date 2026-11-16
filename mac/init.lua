-- agent-voice: hold ⌥Space to dictate. Records on the Mac, transcribes with Whisper on the
-- Linux GPU (Speaches, reached over SSH so it stays bound to localhost), types into the focused app.
-- Linked from ~/.hammerspoon/init.lua by mac/install.sh. Reload: Hammerspoon menu → Reload Config.

local HOST = "yulpher-dev" -- ~/.ssh/config alias of the Linux box
local MODEL = "deepdml/faster-whisper-large-v3-turbo-ct2"
local FFMPEG = "/opt/homebrew/bin/ffmpeg"
local WAV = os.getenv("TMPDIR") .. "agent-voice.wav"
local MIN_SECONDS = 0.4 -- shorter presses are accidental; Whisper hallucinates on near-silence

local recorder, startedAt, alertId

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function transcribe()
  local cmd = string.format(
    [[/usr/bin/ssh -o BatchMode=yes -o ConnectTimeout=5 %s "curl -sf -F 'file=@-;filename=a.wav' -F model=%s http://127.0.0.1:8000/v1/audio/transcriptions" < %q]],
    HOST, MODEL, WAV)
  hs.task.new("/bin/sh", function(code, out, err)
    if code ~= 0 then
      hs.alert.show("Dictado falló: " .. trim(err ~= "" and err or ("exit " .. code)))
      return
    end
    local ok, json = pcall(hs.json.decode, out)
    local text = ok and json and json.text and trim(json.text) or ""
    if text ~= "" then hs.eventtap.keyStrokes(text) end
  end, { "-c", cmd }):start()
end

local function startRecording()
  if recorder and recorder:isRunning() then return end
  startedAt = hs.timer.secondsSinceEpoch()
  alertId = hs.alert.show("🎙 grabando…", "forever")
  recorder = hs.task.new(FFMPEG, function()
    hs.alert.closeSpecific(alertId)
    if hs.timer.secondsSinceEpoch() - startedAt >= MIN_SECONDS then transcribe() end
  end, { "-loglevel", "error", "-y", "-f", "avfoundation", "-i", ":default", "-ar", "16000", "-ac", "1", WAV })
  recorder:start()
end

local function stopRecording()
  if recorder and recorder:isRunning() then recorder:interrupt() end -- SIGINT lets ffmpeg finish the WAV
end

hs.hotkey.bind({ "alt" }, "space", startRecording, stopRecording)
