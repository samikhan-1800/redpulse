# RedPulse 🩸

> **Donate Blood, Save Lives**

A modern Flutter-based blood donation management application designed to connect blood donors with those in need. RedPulse streamlines the process of requesting and donating blood through an intuitive mobile interface.

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange.svg)](https://firebase.google.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📑 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Firebase Setup](#firebase-setup)
  - [Running the App](#running-the-app)
- [Project Structure](#project-structure)
- [Key Features Implementation](#key-features-implementation)
  - [Authentication](#authentication)
  - [Blood Requests](#blood-requests)
  - [Real-time Chat](#real-time-chat)
  - [Biometric Login](#biometric-login)
  - [Location Services](#location-services)
- [Configuration](#configuration)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)
- [Acknowledgments](#acknowledgments)

---

## 🎯 Overview

RedPulse is a comprehensive blood donation platform that bridges the gap between blood donors and recipients. Built as a semester project, it demonstrates modern mobile app development practices using Flutter and Firebase.

**Purpose:** Semester Project  
**Developer:** Sami Khan  
**Version:** 1.0

---

## ✨ Features

### Core Functionality
- 🔐 **Secure Authentication** - Email/password login with biometric support
- 🆘 **Emergency SOS Requests** - Priority blood requests for critical situations
- 📍 **Location-based Matching** - Find nearby donors using Google Maps integration
- 💬 **Real-time Chat** - Communicate with donors/recipients instantly
- 🔔 **Push Notifications** - Stay updated on blood requests and responses
- 👥 **Friend System** - Connect with regular donors
- 👨‍👩‍👧‍👦 **Group Management** - Create and manage donor groups
- 📊 **Donation Tracking** - Monitor your donation history and impact
- 🌓 **Dark Mode** - Comfortable viewing in any lighting condition

### User Experience
- ⚡ **Fast & Responsive** - Optimized performance
- 🎨 **Modern UI** - Beautiful, intuitive interface
- 🔒 **Privacy First** - Secure data handling
- 📱 **Cross-platform** - Works on Android and iOS
- ♿ **Accessible** - Designed for all users

---

## 📱 Screenshots

<p align="center">
  <img src="redpulse_app_screenshots/signup.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/signup_one.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/signup_two.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/signup_three.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/login.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/app_permission.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/dashboard.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/map.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/map_darkmode.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/donor_marker_map.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/marker_map_request.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/request.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/create_request_normal.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/create_request_emergency.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/create_request_sos.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/request_details.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/request_view.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/sos_button.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/my_requests.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/chat_section.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/profile.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/profile_one.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/profile_two.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/donation_history.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/notification_screen.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/dark_mode.jpeg" width="200"/>
  <img src="redpulse_app_screenshots/about_section.jpeg" width="200"/>

</p>

---

## 🛠️ Tech Stack

### Frontend
- **Flutter** - Cross-platform mobile framework
- **Riverpod** - State management
- **Flutter ScreenUtil** - Responsive UI

### Backend & Services
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - Real-time database
- **Firebase Storage** - File storage
- **Firebase Cloud Messaging** - Push notifications
- **Google Maps API** - Location services

### Key Packages
```yaml
dependencies:
  flutter_riverpod: ^2.4.0
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  cloud_firestore: ^4.13.0
  firebase_storage: ^11.5.0
  firebase_messaging: ^14.7.0
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  local_auth: ^2.1.7
  url_launcher: ^6.2.1
  image_picker: ^1.0.4
  shared_preferences: ^2.2.2
```

---

## 🏗️ Architecture

RedPulse follows a clean architecture pattern with clear separation of concerns:

```
lib/
├── core/                 # Core utilities and constants
│   ├── constants/       # App-wide constants
│   └── utils/           # Utility functions
├── data/                # Data layer
│   ├── models/          # Data models
│   ├── providers/       # Riverpod providers
│   └── services/        # Business logic services
└── presentation/        # UI layer
    ├── screens/         # App screens
    └── widgets/         # Reusable widgets
```

### Design Patterns
- **Provider Pattern** - State management with Riverpod
- **Repository Pattern** - Data access abstraction
- **Service Layer** - Business logic separation
- **MVVM** - Model-View-ViewModel architecture

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / VS Code
- Firebase account
- Google Maps API key

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/samikhan-1800/redpulse.git
   cd redpulse
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables**
   
   Create a `local.properties` file in the `android/` directory:
   ```properties
   GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
   ```

### Firebase Setup

1. **Create a Firebase project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project named "RedPulse"

2. **Add Android app**
   - Package name: `com.example.redpulse`
   - Download `google-services.json`
   - Place it in `android/app/`

3. **Add iOS app** (if targeting iOS)
   - Bundle ID: `com.example.redpulse`
   - Download `GoogleService-Info.plist`
   - Place it in `ios/Runner/`

4. **Enable Firebase services**
   - Authentication (Email/Password)
   - Cloud Firestore
   - Firebase Storage
   - Cloud Messaging

5. **Set up Firestore security rules**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId} {
         allow read: if request.auth != null;
         allow write: if request.auth.uid == userId;
       }
       match /bloodRequests/{requestId} {
         allow read: if request.auth != null;
         allow create: if request.auth != null;
         allow update: if request.auth.uid == resource.data.requesterId;
       }
     }
   }
   ```

### Running the App

```bash
# Run in debug mode
flutter run

# Run in release mode
flutter run --release

# Run on specific device
flutter run -d <device_id>

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

---

## 📂 Project Structure

```
redpulse/
├── android/                    # Android native code
├── ios/                        # iOS native code
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   └── app_strings.dart
│   │   └── utils/
│   │       ├── extensions.dart
│   │       └── validators.dart
│   ├── data/
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   ├── blood_request_model.dart
│   │   │   └── biometric_auth_result.dart
│   │   ├── providers/
│   │   │   ├── auth_provider.dart
│   │   │   ├── user_provider.dart
│   │   │   └── request_provider.dart
│   │   └── services/
│   │       ├── auth_service.dart
│   │       ├── database_service.dart
│   │       ├── biometric_service.dart
│   │       └── notification_service.dart
│   ├── presentation/
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   ├── main/
│   │   │   ├── request/
│   │   │   └── chat/
│   │   └── widgets/
│   │       ├── buttons.dart
│   │       ├── cards.dart
│   │       └── common_widgets.dart
│   └── main.dart
├── assets/                     # Images, fonts, etc.
├── pubspec.yaml               # Dependencies
└── README.md
```

---

## 🔑 Key Features Implementation

### Authentication

RedPulse uses Firebase Authentication with enhanced biometric support:

- **Email/Password** - Standard authentication
- **Biometric Login** - Fingerprint/Face ID support
- **Secure Storage** - Encrypted credential storage
- **Auto-login** - Seamless user experience

### Blood Requests

Create and manage blood donation requests:

- **Emergency Levels** - Normal, Emergency, SOS
- **Blood Type Matching** - Automatic compatible donor search
- **Location Tracking** - Hospital location with map integration
- **Status Management** - Active, Completed, Cancelled

### Real-time Chat

Instant messaging between donors and recipients:

- **Firebase Firestore** - Real-time message sync
- **Read Receipts** - Message status tracking
- **Push Notifications** - New message alerts
- **Media Sharing** - Image support

### Biometric Login

Secure and convenient authentication:

- **Hardware Detection** - Automatic capability check
- **Fallback Support** - PIN/Password alternative
- **Error Handling** - Detailed user feedback
- **Cross-platform** - Android & iOS support

### Location Services

Find nearby donors and hospitals:

- **Google Maps Integration** - Interactive maps
- **Geolocation** - Current location detection
- **Distance Calculation** - Proximity-based matching
- **Directions** - Navigate to hospitals

---

## ⚙️ Configuration

### Environment Variables

Configure the following in your environment:

- `GOOGLE_MAPS_API_KEY` - Google Maps API key
- Firebase configuration files

### App Configuration

Modify `lib/core/constants/` files for:

- Color scheme
- Text strings
- API endpoints
- Feature flags

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests
flutter drive --target=test_driver/app.dart
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📧 Contact

**Sami Khan**  
- Email: khansami1800@gmail.com
- GitHub: [@samikhan-1800](https://github.com/samikhan-1800)
- LinkedIn: [Sami Khan](https://www.linkedin.com/in/samikhan1800/ )

**Project Link:** [https://github.com/samikhan-1800/redpulse](https://github.com/samikhan-1800/redpulse)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Google Maps for location services
- Open source community

---

<div align="center">

**Made with Flutter by Sami Khan**

*Donate Blood, Save Lives* 🩸

</div>
