
# RedPulse – Smart Emergency Donor Connection System

RedPulse is a real-time emergency assistance application built using Flutter, Firebase, and Google Maps. It connects people who need urgent help with nearby donors using live location, real-time notifications, and built-in communication features.

## Table of Contents
- [Overview](#overview)
- [Core Features](#core-features)
- [System Workflow](#system-workflow)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [State Management](#state-management)
- [Database Design](#database-design)
- [Installation Guide](#installation-guide)
- [Tech Stack](#tech-stack)
- [API Integrations](#api-integrations)
- [Security and Validation](#security-and-validation)
- [Performance Considerations](#performance-considerations)
- [Future Enhancements](#future-enhancements)
- [Contributors](#contributors)

## Overview
RedPulse enables users to request and donate during emergencies. Users can switch roles dynamically, send SOS alerts, communicate through in-app chat, and view real-time donor locations. The system ensures fast donor-recipient matching and provides detailed analytics for donation history.

## Core Features
- Unified user role (donor or recipient)
- Real-time donor matching using live GPS and blood group
- Emergency request creation
- SOS one-tap emergency alerts
- Manual requests for others
- Push notifications using Firebase Cloud Messaging
- In-app real-time chat between donor and recipient
- Google Maps integration with dynamic markers
- Donation analytics dashboard
- Donation and request history tracking

## System Workflow
1. User registers or logs in.
2. System fetches user location and blood group.
3. User creates a request or toggles donor availability.
4. Donors near the request receive notifications.
5. A donor accepts the request.
6. Chat opens automatically for coordination.
7. Request is marked completed and analytics updated.

## Architecture
The project follows a Clean Architecture approach with MVC-like separation.

Layers include:
- UI Layer (widgets, screens)
- Logic Layer (controllers, providers, Riverpod)
- Data Layer (repositories, services)
- Domain Layer (models)

## Project Structure
```
lib/
 ├─ core/
 ├─ data/
 │   ├─ models/
 │   ├─ repositories/
 │   └─ services/
 ├─ logic/
 │   ├─ providers/
 │   ├─ controllers/
 │   └─ state/
 ├─ ui/
 │   ├─ screens/
 │   ├─ widgets/
 │   ├─ components/
 │   └─ themes/
 └─ main.dart
```

## State Management
- setState() for local UI updates
- Provider for user and location state
- Riverpod for global asynchronous logic

## Database Design (Firestore)

### users collection
```
users/
   uid/
      name
      phone
      bloodGroup
      location
      availability
      donationCount
      lastDonationDate
```

### requests collection
```
requests/
   requestId/
      requestedBy
      bloodGroup
      hospitalLocation
      description
      status
      acceptedBy
```

### chats collection
```
chats/
   chatId/
      messages/
         messageId/
            senderId
            text
            timestamp
```

## Installation Guide

### 1. Clone repository
```
git clone https://github.com/YOUR_USERNAME/RedPulse.git
cd RedPulse
```

### 2. Install dependencies
```
flutter pub get
```

### 3. Add Firebase configuration
Place Firebase config files in:
```
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

### 4. Enable Google Maps APIs in Console
- Maps SDK for Android
- Directions API
- Geocoding API
- Places API

### 5. Run the project
```
flutter run
```

## Tech Stack
- Flutter
- Firebase Authentication
- Firebase Firestore
- Firebase Cloud Messaging
- Google Maps Platform
- Riverpod & Provider

## API Integrations
- Google Maps SDK
- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging
- Geolocation services

## Security and Validation
- Firestore rules to protect sensitive data
- Authentication guards for secure access
- Form validation for request creation and profile updates
- Role-based data access

## Performance Considerations
- Efficient Firestore queries and indexing
- State management to reduce unnecessary rebuilds
- Cached user data to decrease reads
- Lazy loading long lists (history, chats)
- Minimal UI overdraw for smooth animations

## Future Enhancements
- AI-based donor prediction
- Smart hospital dashboard
- Real-time ambulance tracking
- Multi-language support
- Dark mode
- Voice-assisted SOS requests

## Contributors
**Sami Khan** — Developer & Architect  
COMSATS University Islamabad, Wah Campus
