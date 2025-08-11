
# Attendance Face Recognition

A mobile-based attendance system that utilizes **facial recognition** and **GPS validation** to replace traditional fingerprint attendance.  
Built using **Flutter** for the frontend, **Firebase** for authentication & database, and **Flask** (with MTCNN & FaceNet) for face recognition backend.

---

## ✨ Features

### Admin (HRD)
- **Dashboard** – View employee statistics & attendance summary.
- **Register Employee** – Add employee accounts (manual or bulk import via Excel).
- **Set Attendance Location** – Define office location & attendance radius (Haversine formula).
- **Employee List** – View and manage employee profiles.
- **Attendance Detail** – Check detailed logs of employee attendance.
- **Export Excel** – Download attendance logs in Excel format.

### Employee
- **Face Registration** – Capture 3 photos for facial recognition setup.
- **Clock In / Clock Out** – Attendance with location & face verification.
- **View Attendance History** – Check personal attendance records.

---

## 🛠 Tech Stack

### Frontend (Mobile App)
- [Flutter](https://flutter.dev/) – Cross-platform mobile development.
- [Firebase Authentication](https://firebase.google.com/docs/auth) – User login & authentication.
- [Firebase Firestore](https://firebase.google.com/docs/firestore) – Real-time database for attendance records.

### Backend
- [Flask](https://flask.palletsprojects.com/) – Python backend for processing.
- [MTCNN](https://github.com/ipazc/mtcnn) – Face detection.
- [FaceNet](https://github.com/davidsandberg/facenet) – Face embedding & similarity comparison.
- [Haversine Formula](https://en.wikipedia.org/wiki/Haversine_formula) – Location validation within radius.

---

## 📂 Project Structure

```
attendance_face_recognition/
│
├── mobile/               # Flutter mobile app
│   ├── lib/               # Flutter source code
│   ├── pubspec.yaml       # Flutter dependencies
│
├── backend/              # Flask backend
│   ├── app.py             # Main Flask app
│   ├── requirements.txt   # Python dependencies
│
└── README.md
```

---

## ⚙️ Installation

### 1️⃣ Frontend (Flutter)
```bash
cd attendance_face_recognition/mobile

# Install Flutter dependencies
flutter pub get

# Run the app
flutter run
```

---

## 🔑 Environment Variables

### Backend (`.env`)
```
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_PRIVATE_KEY=your_private_key
FIREBASE_CLIENT_EMAIL=your_client_email
```

### Flutter (`lib/config.dart`)
```dart
const String flaskApiUrl = "http://YOUR_FLASK_SERVER_IP:5000";
```

---

## 📜 License
This project is licensed under the MIT License.

A new Flutter project.

1. Create File .env on root project 
2. Create variable API_URL, for the value contact me
3. flutter pub get, flutter run

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
