🔥 RedPulse – Smart Emergency Donor Connection System

A real-time, location-aware blood donation platform built with Flutter, Firebase, and Google Maps to connect donors and recipients faster.

## Table of Contents
- [Overview](#overview)
- [Core Features](#core-features)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [State Management](#state-management)
- [Data Model](#data-model)
- [Firebase Setup](#firebase-setup)
  - [Android](#android)
  - [Web (optional)](#web-optional)
- [Maps Setup](#maps-setup)
- [Environment & Secrets](#environment--secrets)
- [Run & Build](#run--build)
- [Security Rules (Firestore)](#security-rules-firestore)
- [Performance Notes](#performance-notes)
- [Future Enhancements](#future-enhancements)
- [Contributors](#contributors)

## Overview
RedPulse enables users to request blood, volunteer as donors, and coordinate via real-time location, push notifications, and in-app chat. Speed and reliability drive the experience.

## Core Features
- Unified user role: toggle donor availability on/off.
- Emergency / SOS requests with hospital location and blood group.
- Real-time donor matching by proximity and compatibility.
- Push notifications (FCM) for nearby requests and acceptances.
- In-app chat after a donor accepts a request.
- Interactive Google Maps with donors/requests markers and distance hints.
- Donation history and basic analytics (totals, history timeline).

## Architecture
- Clean architecture with clear layers: presentation (screens/widgets), data (services, providers), domain (models).
- Firebase backend: Auth, Firestore, Storage, FCM.
- Location/Maps: geolocator, geocoding, google_maps_flutter.
- Forms/Validation: flutter_form_builder, form_builder_validators.

## Project Structure
```
lib/
  core/              # theme, constants, utils
  data/              # models, services (Firebase/DB), providers
  presentation/      # screens, widgets, navigation
  main.dart          # app entry, Firebase init
android/             # Android build (place google-services.json in android/app)
ios/                  # iOS build (place GoogleService-Info.plist in ios/Runner)
web/                 # Web assets & manifest
```

## State Management
- setState for simple, local UI updates.
- Provider for auth/user/profile basics.
- Riverpod for streams and app-wide logic (requests, chat, notifications, location).

## Data Model
- users: profile, blood group, phone, location, availability, donationCount.
- requests: requester info, bloodGroup, unitsRequired, location, status (pending/accepted/completed/cancelled), acceptedBy, timestamps, chatId.
- chats: participants, lastMessage, unreadCount.
- messages: chatId, senderId/name, content, type, isRead, createdAt.
- notifications: user-targeted alerts, read state.

## Firebase Setup
### Android
1) In Firebase console, register Android app with package name: `com.example.redpulse` (see android/app/build.gradle.kts).
2) Download google-services.json and place it at android/app/google-services.json.
3) Ensure Android Gradle has the Google services plugin (already added in settings.gradle.kts and android/app/build.gradle.kts).
4) Run on device: `flutter run -d <device>`.

### Web (optional)
1) In Firebase console, add a Web app and copy the Web config.
2) Update main.dart FirebaseOptions (search for YOUR_API_KEY etc.) with your real values.

## Maps Setup
- Enable these APIs in Google Cloud Console: Maps SDK for Android, Geocoding API, Places API, Directions API.
- Add your Maps API key to Android local.properties or AndroidManifest as needed (not committed here).

## Environment & Secrets
- Do not commit keys: keep google-services.json, GoogleService-Info.plist, and Maps API keys local.
- Web Firebase config in main.dart should be real values for web builds.

## Run & Build
```
flutter pub get
flutter run                # picks a connected device (Android preferred)
# or choose explicitly
flutter run -d chrome      # web (requires web Firebase config)
flutter run -d windows     # desktop (no Firebase on Windows by default)
```

## Security Rules (Firestore)
Start with restrictive rules and open only what you need:
```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
    match /requests/{id} {
      allow create: if request.auth != null;
      allow read: if true;
      allow update, delete: if request.auth != null && request.auth.uid == resource.data.requesterId;
    }
    match /chats/{chatId}/messages/{msgId} {
      allow read, write: if request.auth != null && request.auth.uid in resource.data.participantIds;
    }
  }
}
```

## Performance Notes
- Use Firestore streams + Riverpod to minimize rebuilds.
- Index common Firestore queries (requests by status, by requesterId).
- Batch updates for chat read receipts.
- Cache location where possible and avoid excessive geocoding calls.

## Future Enhancements
- AI-based donor prediction/ranking.
- Hospital dashboard portal.
- Real-time ambulance tracking.
- Multi-language support and full dark mode.
- Voice-enabled emergency requests.

## Contributors
- Sami Khan — Developer, Architect, Designer (COMSATS University Islamabad, Wah Campus)
