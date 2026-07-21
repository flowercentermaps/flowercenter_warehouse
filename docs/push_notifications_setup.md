# Push Notifications (FCM) — Setup Guide

The warehouse app currently uses **local notifications** (`local_notifier`) which only fire while the app is in the foreground. To get notifications when the app is backgrounded or closed (the goal of plan item **A3**), Firebase Cloud Messaging must be wired in.

The CRM app at `flowercenterdb` already has a complete FCM implementation at `lib/services/push_notification_service.dart` and a `user_push_tokens` table on the Supabase backend. The CRM-side trigger that sends an FCM push when a quotation moves to `pending_transfer` is also already in place.

Only the warehouse-side client needs to be wired up.

---

## What you need to do manually

### 1. Add the warehouse app to your Firebase project
1. Go to the [Firebase Console](https://console.firebase.google.com) → same project the CRM uses
2. Add an **Android app** with the package `com.example.flowercenter_warehouse` (or your real package id — check `android/app/build.gradle`)
3. Download `google-services.json` → drop it into `android/app/`
4. Add an **iOS app** with the bundle id from `ios/Runner.xcodeproj`
5. Download `GoogleService-Info.plist` → drop it into `ios/Runner/`

### 2. Native config

**Android — `android/build.gradle`**:
```gradle
buildscript {
  dependencies {
    classpath 'com.google.gms:google-services:4.4.2'
  }
}
```

**Android — `android/app/build.gradle`** (at the very bottom):
```gradle
apply plugin: 'com.google.gms.google-services'
```

**iOS — `ios/Podfile`**: ensure platform iOS 13.0+.

### 3. Add dependencies to `pubspec.yaml`
```yaml
dependencies:
  firebase_core: ^3.6.0
  firebase_messaging: ^15.1.3
```

Then `flutter pub get` and `cd ios && pod install`.

---

## Wiring up (code I'll write once Firebase config is in place)

Once the config files exist, the implementation is straightforward:

1. **`lib/main.dart`** — initialise Firebase before `runApp`:
   ```dart
   await Firebase.initializeApp();
   ```

2. **`lib/services/push_notification_service.dart`** *(new)* — port from CRM:
   - `requestPermissions()`
   - `registerTokenForUser(String userId)` — writes to `user_push_tokens`
   - `onMessage` / `onMessageOpenedApp` handlers
   - Deep-link payload `{quotation_id: N}` → push `StockCheckScreen(quotationId: N)` via a global navigator key

3. **`lib/features/auth/presentation/providers/auth_provider.dart`** — call `registerTokenForUser` on successful sign-in.

4. **`lib/main.dart`** — add `navigatorKey: rootNavigatorKey` to `MaterialApp` so push handlers can navigate.

5. **Cold-start handling** — call `FirebaseMessaging.instance.getInitialMessage()` in `main()` and stash the deep link until the home screen is mounted.

---

## Tell me when the Firebase config files are in place

Once `google-services.json` and `GoogleService-Info.plist` exist in the repo, the rest of A3 takes about 30 minutes to wire up. Until then, the app still gets notifications via the existing `local_notifier` path when it's in the foreground.
