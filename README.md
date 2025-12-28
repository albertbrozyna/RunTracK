# 🏃‍♂️ RunnerStats – Flutter Training Tracker

A professional mobile application built with Flutter, designed for comprehensive activity tracking, social competition, and precise GPS data management. Powered by OpenStreetMap and Firebase.

---

## ✨ Features

### 👤 User Profile & Social
- **Public Profile Customization:** Edit your display name, bio, and upload a profile picture.
- **Social Discovery:** Search for other athletes, add them to your friends list, and invite them to races.
- **Activity Feed:** Browse your friends' history and view public workouts shared by the community.

### 🛰️ Advanced Tracking & OpenStreetMap
- **OpenStreetMap Integration:** Real-time route visualization using [OpenStreetMap](https://www.openstreetmap.org/) for an open-source mapping experience.
- **Performance Metrics:** Monitor pace (min/km), distance (km), elevation gain, and average speed.
- **Fine-tuned GPS Settings:**
  - Custom distance interval and accuracy control.
  - Anomaly threshold to filter inaccurate GPS pings and location jumps.

### 🏆 Virtual Challenges
- **Virtual Competitions:** Create custom races and compete with friends in real-time.
- **Completion System:** Automatic verification of race completion with instant status updates.

### 🔋 Background Execution & Battery Optimization
- **Background Tracking:** The app continues to track your run even when the screen is off or you are using other apps.
- **⚠️ Important Note for Users:** To ensure the tracking is not interrupted (especially on **Samsung**, **Xiaomi**, or **Huawei** devices), please:
  - Grant "Allow all the time" location permissions.
  - Disable "Battery Optimization" for this app to prevent the system from killing the background service.

---

## 🛠️ Technical Stack

- **Frontend:** Flutter (Dart)
- **Maps:** OpenStreetMap (flutter_map)
- **Backend:** Google Firebase (Firestore & Storage)
- **Location:** Geolocator with Background Service

---

## 🚀 Getting Started

1. **Clone the repository:**
   `git clone https://github.com/YourUsername/YourRepository.git`

2. **Configure Firebase:**
   - Download `google-services.json` (Android) and place it in `android/app/`
   - Download `GoogleService-Info.plist` (iOS) and place it in `ios/Runner/`
   - Enable **Firebase Storage** for profile pictures.

3. **Install dependencies:**
   `flutter pub get`

4. **Run the app:**
   `flutter run`

---
## 👨‍💻 Author
Albert Brożyna - https://github.com/albertbrozyna

---
*Developed for training and fitness enthusiasts.*
