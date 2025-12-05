🔥 RedPulse – Smart Emergency Donor Connection System

A real-time, location-based donor–recipient assistance platform designed to reduce emergency response time and connect people who can save lives.

📌 Table of Contents

Overview

Core Features

System Workflow

Architecture

Project Structure

State Management

Database Design

Installation Guide

Tech Stack

API Integrations

Security & Validation

Performance Considerations

Future Enhancements

Contributors

🩸 Overview

RedPulse is a real-time emergency assistance application built using Flutter, Firebase, and Google Maps Platform.
It enables users to both request blood and donate blood, delivering instant donor-recipient matching through live location tracking, push notifications, and an interactive map interface.

Emergencies require speed. RedPulse aims to bridge the gap between those who need help and those willing to provide it — instantly, reliably, and intelligently.

🚀 Core Features
🧑‍🤝‍🧑 Unified User Role

Users can act as both donor and recipient. A simple availability toggle switches donor mode on or off.

📍 Real-Time Donor Matching

Live GPS location is used to detect the closest eligible donors within a configurable radius.

🩸 Create Emergency Requests

Recipients can create urgent blood requests with patient data, hospital location, and required blood group.

🆘 SOS Emergency Mode

One-tap SOS instantly alerts all nearby available donors.

👥 Manual Request Creation

Users can create a request on behalf of someone else by entering their details and location.

🔔 Instant Push Notifications (FCM)

Donors receive immediate alerts when a request is created close to them.
Recipients are notified when a donor accepts their request.

💬 In-App Chat System

Once a donor accepts a request, both parties can communicate directly inside the app.

🗺️ Interactive Google Maps

Live donor locations

Live request locations

Dynamic markers

Distance calculation

Hospital/patient location preview

📊 Donation Analytics Dashboard

Users can view:

Total donations

Request history

Acceptance history

Monthly statistics

User growth patterns

📂 Donation History

A detailed timeline of all previous donations, requests, and interactions.

🔄 System Workflow
1. User registers/login

Firebase Authentication stores user identity.
Firestore stores profile, blood group, and location.

2. User updates location

Location is synced periodically or when app launches.

3. If user needs blood:

Creates emergency request

Request stored in Firestore

Notification sent to nearby donors

4. Donor sees notification → opens request details

Accept

Decline

5. If accepted:

Recipient notified

Chat session opens

Analytics updated

6. After completion:

Donor’s total donations increment

History recorded

Request marked completed

🧱 Architecture
Clean Architecture with MVC Principles

UI Layer: Widgets, Screens

Controller Layer: Providers, Riverpod, State Managers

Data Layer: Firebase Services, Repositories

Domain Layer: Models, Entities

The app is structured so that changing the database (Firestore) only requires modifying the repository files, not UI or business logic.

Folder Structure Example
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

🔧 State Management

The project uses a hybrid approach:

✔ setState()

For simple UI refresh logic (local widgets).

✔ Provider

Used for user profile, authentication status, and location provider.

✔ Riverpod

Used for:

Requests stream

Donor matching logic

Chat controller

Global application state

This ensures scalability, separation of concerns, and performance optimization.

🗄️ Database Design (Firestore)
Collections
users/
   uid/
      name
      bloodGroup
      phone
      location
      availability
      donationCount
      lastDonationDate

requests/
   requestId/
      requestedBy
      bloodGroup
      hospitalLocation
      description
      status
      acceptedBy

chats/
   chatId/
      messages/
         messageId/
            senderId
            text
            timestamp

🔌 API Integrations
✔ Google Maps SDK

Used for map rendering, markers, and camera movement.

✔ Geolocation API

Used for retrieving live latitude–longitude.

✔ Firebase Cloud Messaging (FCM)

Used for:

Request alerts

Acceptance alerts

Chat notifications

✔ Firebase Authentication

Login, register, secure access.

✔ Cloud Firestore

All real-time data operations.

🛡 Security & Validation
🔐 Firestore Security Rules

Prevent unauthorized access to user data and requests.

✔ Form Validation

Valid phone numbers

Valid email format

Required blood group

Location data must be present

🔄 Protected Routes

Unauthenticated users cannot access dashboard or chat.

⚡ Performance Considerations

Minimum reads by using streams + caching

Using Riverpod to avoid unnecessary widget rebuilds

Lazy loading large lists (history, requests)

Efficient Firestore indexing for queries

Controlled polling for location updates

Using lightweight UI components for faster rendering

🚀 Installation Guide
1. Clone Repository
git clone https://github.com/YOUR_USERNAME/RedPulse.git
cd RedPulse

2. Install Dependencies
flutter pub get

3. Add Firebase config files

google-services.json → /android/app/

GoogleService-Info.plist → /ios/Runner/

4. Enable Google Maps API

Activate:

Maps SDK for Android

Directions API

Geocoding API

Places API

5. Run App
flutter run

🔮 Future Enhancements

AI-based donor prediction system

Hospital dashboard portal

Real-time ambulance tracking

Multi-language support

Dark mode

Voice-enabled emergency request mode

👨‍💻 Contributors

Sami Khan — Developer, Architect, Designer
Project under COMSATS University Islamabad (Wah Campus)