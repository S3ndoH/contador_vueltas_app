# WearOS Persistent Synchronization & Offline Flow

This plan ensures that the WearOS app can record sessions without internet (offline) and automatically sync them to Supabase once the connection is restored, requiring login only once.

## Goals
- **One-time Login**: Persistent session that doesn't force the user to log in every time.
- **Offline Recording**: Robust local storage of training data when offline.
- **Automatic Reconciliation**: Auto-sync pending data when internet becomes available.

## Proposed Changes

### 1. Dependencies [MODIFY] `pubspec.yaml`
- Add `shared_preferences` for persisting the authentication state and minimal metadata.
- Add `connectivity_plus` to detect when the watch is back online.

### 2. Database Service [MODIFY] `database_service.dart`
- Create a `SyncQueue` mechanism.
- Add methods to save/load pending sessions to/from local storage (JSON format for simplicity in `SharedPreferences`).
- Add a `syncPendingData()` method to upload anything stored locally.

### 3. Wear Home Screen [MODIFY] `wear_home.dart`
- Restore the `WearLoginScreen` but as an **optional configuration** (only shown if not logged in).
- Add a "Sincronización" status icon and a background listener for connectivity changes.
- Automatically trigger `syncPendingData()` when connectivity is restored.

### 4. Wear Training Screen [MODIFY] `wear_training.dart`
- If offline: Save training and laps to the local queue immediately.
- If online: Attempt direct upload, but fallback to local queue on failure.
- Ensure the `user_id` is cached locally to allow offline record creation associated with the user.

## Verification Plan
1. **Offline Test**: Disable Wi-Fi/Bluetooth on the watch emulator. Record a session. Verify it's saved locally.
2. **Reconnection Test**: Re-enable connection. Verify the session automatically appears in the mobile app.
3. **Session Persistence Test**: Close and reopen the watch app. Verify it remains "Conectado".
