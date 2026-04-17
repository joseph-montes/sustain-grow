<div align="center">

# 🌱 SustainGrow

### *Farming made sustainable.*

A Flutter mobile application that helps farmers monitor crops, track farm KPIs, check weather forecasts, browse an agri-marketplace, and connect with a farming community — all powered by Firebase.

[![Flutter](https://img.shields.io/badge/Flutter-3.41.5-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?logo=android&logoColor=white)](https://flutter.dev/multi-platform)
[![License](https://img.shields.io/badge/License-Private-red)](.)

</div>

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Firebase Setup](#firebase-setup)
- [Building the APK](#building-the-apk)
- [Firestore Data Model](#firestore-data-model)
- [Contributing](#contributing)

---

## Overview

**SustainGrow** is designed for Filipino farmers who want a digital companion for sustainable agriculture. The app provides real-time crop monitoring, farm performance metrics, community-driven knowledge sharing, and an agricultural marketplace — all from a single mobile app.

> Default weather location: **Quezon City, Philippines** (Open-Meteo API, no API key required).

---

## Features

| Module | Description |
|---|---|
| **Dashboard** | Farm overview with sustainability score, crop count, total area, water usage, carbon saved, and active alerts |
| **Crop Monitor** | Add, edit, and delete crops; track health status, area, planting/harvest dates, and zone |
| **Weather** | Multi-day forecast powered by the [Open-Meteo](https://open-meteo.com/) API |
| **Marketplace** | Browse and cart agricultural products; Firestore-backed catalog with auto-seeding |
| **Community** | Social feed for farmers — post updates, apply category filters, and like posts |
| **Auth** | Email/password sign-up and login via Firebase Authentication |

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | [Flutter](https://flutter.dev) (Material Design 3) |
| Language | Dart `>=3.0.0` |
| State Management | [Provider](https://pub.dev/packages/provider) (`AppProvider`, `CartProvider`) |
| Backend | [Firebase](https://firebase.google.com) (Firestore + Authentication) |
| Storage | Firebase Storage *(declared, not yet wired)* |
| Weather API | [Open-Meteo](https://open-meteo.com/) via `http` package |
| Linting | `flutter_lints` |

---

## Project Structure

```
lib/
├── main.dart                  # App entry point, Firebase init, Provider setup
├── firebase_options.dart      # Auto-generated Firebase config
├── models/
│   └── user_model.dart        # UserModel with Firestore serialization
├── providers/
│   └── app_provider.dart      # Global state: auth, crops, weather, community
├── screens/
│   ├── splash_screen.dart
│   ├── login_page.dart
│   ├── signup_page.dart
│   ├── home_screen.dart       # IndexedStack shell with bottom NavigationBar
│   ├── dashboard_screen.dart
│   ├── crops_screen.dart
│   ├── weather_screen.dart
│   ├── marketplace_screen.dart
│   └── community_screen.dart
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── database_service.dart  # Stub (TODO)
│   └── weather_service.dart   # Open-Meteo HTTP client
├── theme/
│   └── app_theme.dart         # Brand colors, gradients, typography, ThemeData
└── widgets/                   # Shared reusable widgets
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>=3.0.0`
- Android SDK (API 34+) with Java/Kotlin 17
- A Firebase project (see [Firebase Setup](#firebase-setup))

### Installation

```bash
# Clone the repository
git clone https://github.com/your-username/sustain-grow.git
cd sustain-grow

# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

---

## Firebase Setup

This project requires a Firebase project with **Authentication** and **Firestore** enabled.

1. Go to the [Firebase Console](https://console.firebase.google.com/) and create a project.
2. Enable **Email/Password** sign-in under **Authentication > Sign-in method**.
3. Create a **Firestore Database** in production or test mode.
4. Register your Android app with package name `com.sustain.myapp`.
5. Download `google-services.json` and place it at `android/app/google-services.json`.
6. Run `flutterfire configure` to regenerate `lib/firebase_options.dart` if needed.

### Firestore Collections

| Collection | Description |
|---|---|
| `users/{uid}` | User profile + `farm` stats map |
| `users/{uid}/crops/{cropId}` | Individual crop records |
| `posts/{postId}` | Community feed posts |
| `products/{productId}` | Marketplace catalog (auto-seeded on first load) |

---

## Building the APK

### Debug APK (for testing/sideloading)

```bash
flutter build apk --debug
```

Output: `build/app/outputs/apk/debug/SustainGrow-debug.apk`

### Release APK

```bash
flutter build apk --release
```

> **Note:** For release builds, configure a signing keystore in `android/app/build.gradle` before distributing to end users.

### Installing on Android (Sideload)

1. Transfer `SustainGrow-debug.apk` to the device.
2. On the device, go to **Settings > Security > Install unknown apps** and allow your file manager.
3. Tap the APK file to install.

---

## Firestore Data Model

```
users/
  {uid}/
    name: string
    email: string
    createdAt: timestamp
    farm:
      totalCrops: number
      totalAreaHectares: number
      sustainabilityScore: number
      waterUsageLiters: number
      carbonSavedKg: number
    crops/
      {cropId}/
        name: string
        type: string
        health_status: string
        area_hectares: number
        zone: string
        createdAt: timestamp

posts/
  {postId}/
    content: string
    author: string
    category: string
    createdAt: timestamp
    likes: number
    comments_count: number

products/
  {productId}/
    name: string
    category: string
    price: number
    description: string
```

---

## Contributing

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "feat: add your feature"`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a pull request.

---

<div align="center">

Made with Flutter · Powered by Firebase · Built for Filipino Farmers 🇵🇭

</div>
