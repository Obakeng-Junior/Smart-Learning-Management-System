# 📚 Smart Learning Management System

An advanced learning management system (LMS) designed to enhance student learning through personalized support, intelligent tutoring, and progress-driven recommendations. The system integrates a **Flutter mobile application** for students with an **ASP.NET Core MVC admin dashboard** for management and analytics.

---

## 🚀 Project Overview

This project aims to address the challenge of learning platforms by introducing **adaptive and intelligent learning support**. Instead of static content delivery, the system tracks student progress, learning behavior, and interactions to provide personalized assistance.

The platform is suitable for academic institutions and was developed as part of an **IT research and final-year project**.

---

## 🧩 System Architecture

The system consists of two main components:

### 📱 Mobile Application (Flutter)

* Student authentication
* Course browsing and enrollment
* Lesson and content viewing
* Student progress tracking
* Smart Tutor interaction
* Rule-based smart recommendations

### 🖥️ Admin Web Application (ASP.NET Core MVC)

* Student management
* Course and content management
* Monitoring student enrollment and progress
* AI Tutor API integration
* Centralized data management

---

## 🤖 Smart Tutor (ML.NET Web API)

The Smart Tutor is implemented using a **custom ML.NET-powered Web API**:

* Uses a **CSV-based dataset** containing questions and correct answers
* Processes student questions sent from the Flutter app via REST API
* Matches and predicts the most relevant response
* Returns structured answers to the mobile app

This approach avoids dependency on third-party AI APIs and ensures full control over the model and data.

---

## 🎯 Key Features

* 📊 **Student Progress Tracking**
* 🧠 **Smart Tutor for Learning Support**
* 🎓 **Course Enrollment System**
* 🔍 **Smart Rule-Based Recommendations**
* 🔐 **Secure Authentication**
* ☁️ **Firebase Firestore Integration**
* 🔄 **REST API Communication**

---

## 🛠️ Technologies Used

### Mobile App

* Flutter (Dart)
* Firebase Authentication
* Firebase Firestore
* REST APIs

### Backend / Admin

* ASP.NET Core MVC
* C#
* Entity Framework Core
* ML.NET

---

## 🔐 Configuration (API Key)

This project uses Firebase.  
For security reasons, API keys are **not included** in the repository.

To run the app:

1. Create a Firebase project
2. Enable Authentication and Firestore
3. Run the app with:

```bash
flutter run --dart-define=API_KEY="YOUR_FIREBASE_API_KEY"
