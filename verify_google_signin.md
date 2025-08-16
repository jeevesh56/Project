# Fix Google Sign-In Configuration

## Current Issues:
1. **Wrong google-services.json**: You have `rit-grubpoint` project config instead of `smart-ai-finance-tracker`
2. **Package name mismatch**: Config has `com.visionaries.grubpoint` but app uses `com.example.smart_ai`
3. **Missing SHA-1 fingerprint**: Your SHA-1 needs to be added to Firebase

## Steps to Fix:

### 1. Get Correct google-services.json
- Go to [Firebase Console](https://console.firebase.google.com/)
- Select **smart-ai-finance-tracker** project (not rit-grubpoint)
- Go to **Project Settings** (gear icon)
- In **Your apps** section, find your Android app
- Add SHA-1: `0F:D1:94:2D:5F:CC:0B:7F:04:FE:09:48:1B:3C:A9:78:0B:70:07:D9`
- Download new `google-services.json`

### 2. Replace google-services.json
- Replace `Project/android/app/google-services.json` with the new one
- Make sure package name matches: `com.example.smart_ai`

### 3. Enable Google Sign-In
- In Firebase Console → **Authentication** → **Sign-in method**
- Enable **Google** provider
- Add authorized domains if needed

### 4. Test
- Run `flutter clean`
- Run `flutter pub get`
- Test Google Sign-In - should show account picker dialog

## Your SHA-1 Fingerprint:
```
0F:D1:94:2D:5F:CC:0B:7F:04:FE:09:48:1B:3C:A9:78:0B:70:07:D9
```

## Expected Result:
After fixing, clicking "Login with Google" should show the account selection dialog like in the image, with options to:
- Choose from existing Google accounts
- Add another account
- Continue without creating an account



