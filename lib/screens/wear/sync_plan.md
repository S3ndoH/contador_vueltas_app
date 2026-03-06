# WearOS Data Synchronization Plan

The goal is to ensure that training sessions recorded on the WearOS watch are synchronized with the Supabase backend and correctly displayed in the main Android application's history.

## Context
- The WearOS app currently has a "Local-First" approach (records laps even if offline/unlogged).
- Mandatory login on the watch was reverted based on user preference.
- To sync with the phone, the watch **must** eventually have a valid Supabase session (UID) to associate the data.

## Proposed Changes

### 1. Unified Backend Association
Ensure both WearOS and Android apps use the same Supabase project and tables. (Already implemented, but verifying consistency).

### 2. Synchronization Feedback & Trigger
- **Home Screen (WearOS)**: Clearly show the sync status.
- **Improved Sync Logic**: If the watch is in "MODO LOCAL" (not logged in), provide a "Sincronizar" option that opens a simplified login/pairing screen *only when requested*, rather than making it mandatory at startup.

### 3. Data Visibility on Phone
- The `HomeScreen` on Android fetches data from the `training_summaries` view.
- Any session uploaded from the watch with the same `user_id` will automatically appear on the phone's list.

### 4. Implementation Steps [WIP]
- [ ] Add a "LOGIN / SYNC" button to the `WearHomeScreen` only when in "MODO LOCAL".
- [ ] Ensure `WearTrainingScreen` attempts to upload data as soon as a session is established.
- [ ] Verify that the `user_id` is being correctly applied to sessions created on the watch.

## Verification Plan
1. Record a session on the watch in "MODO LOCAL".
2. Log in on the watch.
3. Verify the session is uploaded to Supabase.
4. Open the Android app and verify the session appears in "Sesiones Recientes".
