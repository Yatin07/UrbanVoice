# CivicConnect - Crowdsourced Civic Issues App

A comprehensive Flutter application with Firebase backend for reporting and managing civic issues. Citizens can report issues with a single tap, and the system automatically routes them to the appropriate local authorities.

## Features

### For Citizens
- **One-tap reporting**: Camera → GPS → Auto-routing to authorities
- **Smart image composition**: Automatic watermarking with location, timestamp, and map thumbnail
- **Real-time tracking**: Track issue status from submission to resolution
- **Cross-platform**: Works on Android and iOS

### For Authorities
- **Real-time dashboard**: See assigned issues instantly
- **Push notifications**: Get notified of new issues via FCM
- **Status management**: Update issue status and add remarks
- **Geographic filtering**: Only see issues in your jurisdiction

### Backend Intelligence
- **Automatic assignment**: Issues routed by pincode → polygon → distance → state fallback
- **No cross-contamination**: Authorities only see their assigned issues
- **Comprehensive logging**: Full audit trail of all assignments
- **Scalable architecture**: Cloud Functions handle routing logic

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flutter App   │    │   Firebase       │    │  Cloud Function │
│                 │    │                  │    │                 │
│ • Camera        │───▶│ • Authentication │◄───│ • Auto-assign   │
│ • GPS           │    │ • Firestore      │    │ • FCM notify    │
│ • Image Compose │    │ • Storage        │    │ • Logging       │
│ • Upload        │    │ • Messaging      │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.4.0+)
- Firebase CLI
- Node.js (18+) for Cloud Functions
- Google Maps API key (for static maps)
- Android Studio / Xcode for mobile development

### 1. Firebase Project Setup

1. **Create Firebase Project**
   ```bash
   # Install Firebase CLI
   npm install -g firebase-tools
   
   # Login to Firebase
   firebase login
   
   # Create new project or use existing
   firebase projects:create your-project-id
   ```

2. **Enable Firebase Services**
   - Authentication (Email/Password, Google Sign-In)
   - Firestore Database
   - Firebase Storage
   - Cloud Functions
   - Cloud Messaging (FCM)

3. **Configure Firebase for Flutter**
   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase for your Flutter project
   cd civicconnect_app
   flutterfire configure --project=your-project-id
   ```

### 2. Google Maps API Setup

1. **Enable APIs in Google Cloud Console**
   - Static Maps API
   - Geocoding API

2. **Get API Key**
   - Create API key in Google Cloud Console
   - Restrict to your app's package name
   - Add key to `lib/screens/report_issue_page.dart`:
   ```dart
   static const String _googleMapsApiKey = 'YOUR_ACTUAL_API_KEY';
   ```

### 3. Android Configuration

1. **Update Package Name**
   - Ensure `android/app/build.gradle.kts` has correct `applicationId`
   - Must match Firebase project configuration

2. **Add Permissions** (already configured)
   ```xml
   <uses-permission android:name="android.permission.CAMERA" />
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
   <uses-permission android:name="android.permission.INTERNET" />
   ```

3. **SHA-1 Fingerprint**
   ```bash
   # Get debug SHA-1
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # Add to Firebase Console → Project Settings → Your Apps → SHA certificate fingerprints
   ```

### 4. iOS Configuration

1. **Add Permissions to Info.plist**
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>This app needs camera access to report civic issues</string>
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>This app needs location access to report civic issues</string>
   ```

2. **Configure Google Sign-In**
   - Add `GoogleService-Info.plist` to iOS project
   - Configure URL schemes in Xcode

### 5. Cloud Functions Deployment

1. **Install Dependencies**
   ```bash
   cd functions
   npm install
   ```

2. **Deploy Functions**
   ```bash
   firebase deploy --only functions
   ```

3. **Set Environment Variables** (if needed)
   ```bash
   firebase functions:config:set someservice.key="THE API KEY"
   ```

### 6. Firestore Setup

1. **Deploy Security Rules**
   ```bash
   firebase deploy --only firestore:rules
   ```

2. **Seed Sample Data**
   ```dart
   // Run in your Flutter app (one-time setup)
   import 'package:civicconnect/services/authorities_seeder.dart';
   
   await AuthoritiesSeeder.seedSampleAuthorities();
   ```

3. **Create Admin Users**
   - Register users with Firebase Auth
   - Add custom claims or admin collection entries
   - Map users to authority IDs

### 7. Build and Run

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Run on Device**
   ```bash
   # Android
   flutter run -d android
   
   # iOS
   flutter run -d ios
   ```

## Data Models

### Issues Collection
```javascript
{
  "imageUrl": "https://storage.googleapis.com/...",
  "thumbUrl": "https://storage.googleapis.com/...", // optional
  "latitude": 12.9716,
  "longitude": 77.5946,
  "address": "MG Road, Bangalore, Karnataka 560001",
  "pincode": "560001",
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "Pending", // Pending | InProgress | Resolved
  "assignedTo": "ka_bangalore_bbmp",
  "userId": "user123",
  "originalImageName": "IMG_20240115_103000.jpg",
  "storagePath": "issues/raw/issue123.jpg"
}
```

### Authorities Collection
```javascript
{
  "name": "Greater Chennai Corporation",
  "state": "TN",
  "district": "Chennai",
  "pincodes": ["600001", "600002", "..."],
  "center": { "_latitude": 13.0827, "_longitude": 80.2707 },
  "adminUserId": "chennai_admin_001",
  "fcmTokens": ["token1", "token2"],
  "polygon": [[lat1, lng1], [lat2, lng2], "..."] // optional
}
```

## Testing Checklist

### 1. Authority Assignment Testing
```bash
# Test different locations
1. Report issue in Chennai (pincode 600001) → should assign to tn_chennai_greater_corp
2. Report issue in Bangalore (pincode 560001) → should assign to ka_bangalore_bbmp
3. Report issue in unknown pincode → should fallback appropriately
```

### 2. Security Testing
```bash
# Test access controls
1. Admin can only see their authority's issues
2. Citizens can create issues but not modify assignments
3. Cross-authority access is blocked
```

### 3. FCM Testing
```bash
# Test notifications
1. Admin receives notification when issue assigned
2. Invalid tokens are cleaned up automatically
3. Background notifications work correctly
```

## Production Deployment

### 1. Environment Configuration
- Set production Firebase project
- Configure production Google Maps API key
- Update security rules for production
- Set up monitoring and alerting

### 2. Performance Optimization
- Enable Firestore offline persistence
- Implement image compression
- Add caching for static data
- Optimize Cloud Function cold starts

### 3. Monitoring
- Set up Firebase Performance Monitoring
- Configure Crashlytics
- Monitor Cloud Function logs
- Track assignment success rates

## API Keys and Security

⚠️ **Important Security Notes:**

1. **Google Maps API Key**: Replace placeholder in `report_issue_page.dart`
2. **Firebase Config**: Ensure `google-services.json` is not committed to public repos
3. **Security Rules**: Test thoroughly before production deployment
4. **FCM Tokens**: Implement token rotation and cleanup

## Troubleshooting

### Common Issues

1. **Build Errors**
   ```bash
   flutter clean
   flutter pub get
   cd android && ./gradlew clean && cd ..
   flutter run
   ```

2. **Firebase Connection Issues**
   - Verify `google-services.json` is in correct location
   - Check package name matches Firebase configuration
   - Ensure SHA-1 fingerprint is added to Firebase Console

3. **Location/Camera Permissions**
   - Check permissions are declared in manifests
   - Test on physical device (emulator has limitations)
   - Verify permission request flow in app

4. **Cloud Function Errors**
   - Check function logs: `firebase functions:log`
   - Verify Firestore security rules allow function access
   - Test function locally: `firebase emulators:start`

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the repository
- Check Firebase documentation
- Review Flutter documentation
- Test with Firebase emulators for development

---

**Built with ❤️ for better civic engagement**
