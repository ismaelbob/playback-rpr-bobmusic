# PlaybackRPR — AGENTS.md

## Architecture

Two-component REAPER web interface:

- **`session_bridge.lua`** — ReaScript. Runs in REAPER, enumerates open project tabs via `reaper.EnumProjects()`, writes JSON to `reaper.GetResourcePath() .. "/Plugins/reaper_www_root/playback_data.json"`.
- **`playback.html`** — Served by REAPER's built-in HTTP server from `reaper_www_root/`. Uses `main.js` (REAPER-provided) for WebSocket communication. Fetches `playback_data.json` for project list, then uses `wwr_req()` protocol for live data (REGION, TRACK, TRANSPORT commands).

## Setup gotchas

- **`BRIDGE_CMD`** (`playback.html:const BRIDGE_CMD`): must be manually set to the REAPER action Command ID of `session_bridge.lua`. Get it from Actions → right-click → "Copy selected action Command ID" (format `_RSxxxxxxxxxxxxx`). Default placeholder will fail at runtime.
- **`TAB_CMD_BASE`** (`playback.html:const TAB_CMD_BASE`): defaults to `40830` (vanilla REAPER "Go to project tab 01"). Verify in Actions list; adjust if REAPER version differs.
- **File placement**: `playback.html` goes in `reaper_www_root/`, `session_bridge.lua` goes in `Scripts/`.
- **`playback_data.json`** is gitignored (not committed). Generated at runtime by `session_bridge.lua` each time the user taps Refresh.

## Protocol notes

- WebSocket lives on `main.js` (loaded via `<script src="main.js">`). Functions: `wwr_start()`, `wwr_req(cmd)`, `wwr_req_recur(cmd, ms)`. Response handler: `wwr_onreply(results)` — one call per response, lines split by `\n`, fields by `\t`.
- Track index: `0` = master, `1+` = user tracks. `TRACK` response has no end-of-list marker; batching is tracked via an `NTRACK`-detected flag that fires render at end of `wwr_onreply`.
- Region commands: `SET/POS_STR/r<N>` jumps to region N start. `SET/POS_STR/0` jumps to absolute position 0. Navigation buttons (`◀◀`/`▶▶`) iterate `state.regions` by position order, not via REAPER's `SET/POS_STR/+`/`-` (which would hit markers too).
- Tab switch: sends `TAB_CMD_BASE + index` then waits 500ms before querying `REGION`/`TRACK` (REAPER needs time to switch project context).
- Volume slider: HTML range `0-150`, sent as `SET/TRACK/N/VOL/<val/100>`. Range 0-1.5 where `1.0 = 0dB`.
- Track controls use event delegation on `#track-list` (click for M/S, input for slider live preview, change to commit volume).
- Transport commands: `1007` = play, `1016` = pause/stop.
- Tab index command: `TAB_CMD_BASE + N` where TAB_CMD_BASE = 3122 ("switch to project N").

## Transport polling

- **`wwr_req_recur("TRANSPORT", 100)`** — 100ms interval. Parses tab-separated fields: playstate, position, isRepeatOn, positionStr.
- Playstate values: `0` = stopped, `1` = playing, `5` = paused (pause while playing). `ps === 1 || ps === 5` is treated as "playing".
- On playstate transition to `0` (stopped), NEXT queue and LOOP state are cleared automatically.

## LOOP region

- Toggle via `btn-loop` (`↻` button). Activates on current active region.
- **state**: `state.loopActive` (boolean), `state.loopRegionId` (region ID).
- On activate: sends `SET/POS_STR/r<N>` to jump cursor to loop region start immediately.
- **Trigger** (TRANSPORT handler, line ~281): `position >= loopR.end - 0.5` → sends `SET/POS_STR/r<N>` to seek back. The `-0.5` gives a 500ms window (5 polls) for REAPER to process the seek before playhead reaches the end.
- Requires REAPER seeking mode: "Do not change playback position immediately when seeking... before seeking" — the seek moves the edit cursor but playback continues from current position; when play reaches the cursor, it jumps.
- Cleared on: stop, NEXT queue activation, project switch, manual toggle.

## NEXT queue

- Tap an inactive region while playing → that region becomes "NEXT".
- **state**: `state.nextRegionId` (region ID), `state._queueTriggerPos` (end time of currently-playing region).
- On tap: sets `nextRegionId`, `_queueTriggerPos = currentRegion.end`, sends `SET/POS_STR/r<N>` immediately (moves edit cursor to target), disables LOOP, shows badge + status.
- **Trigger A** (TRANSPORT handler, line ~272): `position >= _queueTriggerPos - 0.5` → clears queue, sends seek again, re-renders regions.
- **Trigger B — defensive** (highlightActiveRegion, line ~524): if playhead position enters a region whose ID still matches `state.nextRegionId`, queue is auto-cancelled with `showStatus("Queue cancelled")`. This catches edge cases where timing causes the position to jump past the trigger threshold.
- Tap a region that's already NEXT → cancels queue (`showStatus("Queue cancelled")`).
- Cleared on: stop, project switch, manual cancellation, NEXT auto-trigger, defensive trigger.

## Stop button

- Sends `1016` (pause/stop) + `SET/POS_STR/0` (cursor to start of song).
- Inline cleanup: clears `nextRegionId`, `_queueTriggerPos`, `loopActive`, `loopRegionId`, disables LOOP button UI, re-renders regions.
- Play button toggles between `1007` (play) and `1016` (pause) based on current playstate.

## Key thresholds

| Context | Threshold | Why |
|---|---|---|
| highlightActiveRegion region match | `pos >= r.start - 0.05` | 50ms tolerance for floating point |
| NEXT/LOOP trigger | `pos >= end - 0.5` | 500ms before region end (5 polls at 100ms) |
| Region nav skip (next/prev) | `start > pos + 0.1` / `end < pos - 0.1` | Skip current region on manual nav |
| Transport polling | 100ms | Balance responsiveness vs load |
| silentPoll | 3000ms | Fetch playback_data.json for project list |

## Race conditions & mitigations

- **NEXT/LOOP trigger timing**: The `SET/POS_STR` command seeks the edit cursor but does NOT change playback position (per "before seeking" mode). If TRANSPORT response arrives before the seek takes effect, `highlightActiveRegion` might detect the position in the wrong region.
- **Defensive cancellation**: `highlightActiveRegion` checks `state.regions[idx].id === state.nextRegionId` and cancels the queue if the playhead entered a queued region. This eliminates race conditions between the TRANSPORT trigger and the actual position update.
- **LOOP vs NEXT conflict**: LOOP is disabled when NEXT is activated (line ~509), and NEXT trigger checks `state.nextRegionId === null` before firing LOOP (line ~279). Both can't run simultaneously.

## Cross-platform

- Linux path: `~/.config/REAPER/`
- Windows path: `%APPDATA%\REAPER\`
- Lua script constructs file path with forward slashes; REAPER normalizes on both platforms.
