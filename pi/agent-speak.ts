// Speaks pi's final reply through ~/.local/bin/agent-speak (local Speaches/Kokoro TTS).
// Mute: `touch ~/.cache/agent-speak.off`. Stop playback: /speak-stop.
import { spawn } from "node:child_process";
import { homedir } from "node:os";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const SPEAK = `${homedir()}/.local/bin/agent-speak`;

function lastAssistantText(entries: any[]): string {
	for (let i = entries.length - 1; i >= 0; i--) {
		const msg = entries[i]?.message;
		if (entries[i]?.type !== "message" || msg?.role !== "assistant") continue;
		const content = typeof msg.content === "string" ? [{ type: "text", text: msg.content }] : msg.content ?? [];
		const text = content.filter((b: any) => b?.type === "text").map((b: any) => b.text).join("\n");
		if (text.trim()) return text;
	}
	return "";
}

function run(args: string[], input = ""): void {
	const child = spawn(SPEAK, args, { stdio: ["pipe", "ignore", "ignore"], detached: true });
	child.on("error", () => {}); // missing script must never break pi
	child.stdin.end(input);
	child.unref();
}

export default function (pi: ExtensionAPI) {
	// agent_settled = no retries/continuations left, so we speak once per reply.
	pi.on("agent_settled", async (_event, ctx) => {
		const text = lastAssistantText(ctx.sessionManager.getBranch());
		if (text) run([], text);
	});
	pi.on("agent_start", async () => run(["--stop"]));
	pi.registerCommand("speak-stop", { description: "Stop TTS playback", handler: async () => run(["--stop"]) });
}
