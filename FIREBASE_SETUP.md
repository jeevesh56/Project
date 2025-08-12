# Firebase Setup Guide for Smart AI App

## 🚨 IMPORTANT: You need to complete these steps to fix Google Sign-In

### 1. Download Real Configuration Files from Firebase Console

**Go to:** [Firebase Console](https://console.firebase.google.com/)
**Select your project:** `smart-ai-finance-tracker-app`

#### For Android:
1. Click "Add app" → Choose **Android**
2. Package name: `com.example.smart_ai`
3. Download `google-services.json`
4. **Replace** the placeholder file at: `android/app/google-services.json`

#### For iOS:
1. Click "Add app" → Choose **iOS** 
2. Bundle ID: `com.example.smartAi`
3. Download `GoogleService-Info.plist`
4. **Replace** the placeholder file at: `ios/Runner/GoogleService-Info.plist`

### 2. Enable Google Sign-In in Firebase Console

1. Go to **Authentication** → **Sign-in method**
2. Click on **Google** provider
3. Make sure it's **Enabled**
4. Add your **Support email**
5. Click **Save**

### 3. Add Authorized Domains

In **Authentication** → **Settings** → **Authorized domains**, add:
- `localhost`
- `127.0.0.1`
- Your actual domain (if deploying)

### 4. Update firebase_options.dart

After downloading the real config files, update `lib/firebase_options.dart` with the actual values:

- Replace `YOUR_ANDROID_APP_ID` with the real Android app ID
- Replace `YOUR_IOS_APP_ID` with the real iOS app ID
- Replace `YOUR_ANDROID_CLIENT_ID` with the real Android client ID
- Replace `YOUR_IOS_CLIENT_ID` with the real iOS client ID

### 5. Test the Setup

```bash
flutter clean
flutter pub get
flutter run
```

### 6. Current Status

✅ **Completed:**
- Added Google Services plugin to Android build files
- Created placeholder configuration files
- Updated firebase_options.dart structure

❌ **Still Needed:**
- Download real configuration files from Firebase Console
- Replace placeholder values with real values
- Enable Google Sign-In in Firebase Console

### 7. Troubleshooting

If you still get "Google provider not enabled" error:
1. Make sure you downloaded the **real** config files (not the placeholders)
2. Verify Google Sign-In is enabled in Firebase Console
3. Check that your package name/bundle ID matches exactly
4. Ensure you're using the latest configuration files

### 8. File Locations

- **Android:** `android/app/google-services.json`
- **iOS:** `ios/Runner/GoogleService-Info.plist`
- **Web:** Already configured in `firebase_options.dart`

---

**Note:** The placeholder files I created will NOT work. You MUST download the real configuration files from Firebase Console and replace these placeholders.
