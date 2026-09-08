# Changelog

## Unreleased

* **Fixed sync cancellation races** (#26): `cancelSync()` used to set its cancel flag, clear `isSyncing` and reset the flag synchronously, so a running loop could miss the whole cancellation window while a second sync started on top of it. Runs are now identified by a generation counter, the flag is never reset behind a live run, and the slot is released only when the loop actually unwinds (with a 60s takeover for a wedged run).
* **Cancellation no longer kills unrelated requests** (#26): sync uploads are tracked individually and cancelled by identity, instead of cancelling every task on the shared foreground session — which also aborted token refreshes (surfacing as `.networkError`) and telemetry.
* **No more duplicate replays from the outbox** (#27): the sync path no longer writes outbox items. They carried no anchors and no progress deltas, so a successful replay re-sent records that `SyncState` had already counted. `SyncState` is now the single source of resumable progress; leftover items from older versions are still drained and cleaned up.
* **Background chunk size is decided by app state** (#24): observer-driven syncs, unlock resumes and network resumes ran with the 2000-record foreground chunk (~1.3 MB) while the app was in the background. The chunk size is now re-evaluated every round from the actual app state.
* **Lower peak memory per upload** (#28): the payload is no longer written to disk and read back before being sent, and `logPayloadSummary` no longer re-parses the whole payload when logging is disabled (the default in release builds).
* **Upload failures are visible** (#29): `NSURLErrorCancelled` is no longer suppressed. Every upload now records request id, declared bytes, `countOfBytesSent` against `countOfBytesExpectedToSend`, HTTP status, error domain/code and, for a cancellation, whether it came from `cancelSync()`, background expiration or the system. Failures are logged at a level that survives release builds.
* **Request attribution headers** (#30): every SDK request now sends `X-Open-Wearables-SDK-Version`, `X-Open-Wearables-SDK-Platform`, a `User-Agent` with SDK version, iOS version and device model, and a per-request `X-Request-Id` (reused across a 401 retry). Outbox uploads also send `X-Open-Wearables-Outbox-Item`.
* **Removed the manual `Content-Length` header** (#32), which is reserved and managed by Foundation, and the unused `bufferLock` (#33).
* **HTTP 4xx no longer advances sync progress**: a 400 (including the production `ClientDisconnect`) fails the chunk so cursors stay put and the next wake rebuilds the payload. Cancelled or superseded sync generations do not write `SyncState`. Late outbox callbacks after `signOut` are ignored.

## 0.14.0

* **Fixed full export poisoning**: when the first upload of a full export failed (offline, backend down, app killed), subsequent triggers overwrote the session as incremental without anchors — causing an infinite re-upload loop of old data. Full-export mode is now sticky until completed; already-poisoned devices self-heal.
* **Fixed anchor loss on capture errors**: anchor capture silently swallowed errors (e.g. locked device) and ignored deleted objects in pagination, marking types as complete with a missing/stale anchor. Errors now pause sync; deleted objects count toward query limits.
* **Hardened outbox retries**: retries moved from parallel foreground requests to a serialized background `URLSession` (survives app kill, 1 connection per host). Payloads are preserved on transient failures, dropped on 4xx, expired after 7 days.
* **Background time management**: sync pauses before background time runs out instead of getting killed mid-upload. New `didBecomeActive` observer resumes sync immediately when the app returns to foreground.
* **New `getSyncStatus()` fields**: `initialExportDone` (Bool) and `isSyncing` (Bool) — allows apps to show progress UI during the initial historical export.
* **Removed dead code**: legacy per-type sync path (`syncType`, `enqueueBackgroundUpload`, `chunkSize`).

## 0.13.0

* **Sync telemetry**: new `/logs` endpoint integration for initial full sync diagnostics.
  - `historical_data_sync_start` event sent before the first payload with per-type record counts, time range, and device state.
  - `historical_data_type_sync_end` event sent per data type as each completes (fire-and-forget), with record count, duration, success status, and device state snapshot.
  - Device state includes battery level/state, thermal state, low power mode, RAM usage, and foreground/background task type.
  - Types with zero records are excluded from end events.
  - Start event is sent for both fresh and resumed full exports.

## 0.12.0

* **Source device name**: added `name` field to the source object in health data payloads, providing human-readable device identification alongside existing device metadata.

## 0.11.0

* **Smarter token refresh error handling**: token refresh failures are now classified as either `authFailure` (refresh token rejected with 401/403) or `networkError` (timeout, DNS, 5xx). Only genuine auth failures trigger user disconnect — transient network errors during refresh no longer force sign-out, allowing the SDK's retry mechanism to recover automatically.

## 0.10.0

* **Combined payloads**: all health data types are now merged into a single payload per sync round instead of separate requests per type.
* **Interleaved sync**: data is fetched round-robin across all types (newest to oldest) instead of sequentially type-by-type.
* **Streaming JSON serialization**: payloads are serialized directly to the network stream, reducing memory usage from O(n) to O(depth).
* **Token refresh fix**: fixed stale credential being reused across sync rounds after a token refresh — credential is now read fresh from Keychain before each upload.
* **Bearer prefix normalization**: access tokens returned by the refresh endpoint without the `Bearer ` prefix are now handled correctly.
* **Sign-out reliability**: `signOut()` now guarantees state cleanup even if the native call throws.
* **Cleaned up logging**: removed verbose debug logs and all token/credential values from log output. Logs now show only essential sync lifecycle events, payload summaries, and HTTP statuses.

## 0.9.0

* Initial tracked release.
