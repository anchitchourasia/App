<![CDATA[<div align="center">

<img src="https://img.shields.io/badge/HEG-HRMS-0EA5A4?style=for-the-badge&logoColor=white" height="60"/>

# 🏢 HEG HRMS
### Human Resource Management System

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Spring Boot](https://img.shields.io/badge/Spring_Boot-3.x-6DB33F?style=flat-square&logo=springboot&logoColor=white)](https://spring.io/projects/spring-boot)
[![Oracle DB](https://img.shields.io/badge/Oracle-Database-F80000?style=flat-square&logo=oracle&logoColor=white)](https://www.oracle.com/database/)
[![WebSocket](https://img.shields.io/badge/WebSocket-STOMP-0EA5A4?style=flat-square&logo=socket.io&logoColor=white)]()
[![License](https://img.shields.io/badge/License-Private-red?style=flat-square)]()

> A full-stack mobile HR Management System built with **Flutter** + **Spring Boot**, designed for enterprise workforce management with real-time chat, insurance handling, attendance tracking, and more.

---

</div>

## ✨ Features

| Module | Description |
|--------|-------------|
| 🏠 **Dashboard** | Central hub with quick navigation to all modules |
| 👥 **Employee Management** | View, search, and manage employee records |
| 📅 **Attendance Tracking** | Mark and view attendance with date filtering |
| 💬 **Real-time Chat** | WebSocket (STOMP) based employee ↔ admin messaging |
| 🔔 **Push Notifications** | Local notifications for new messages & updates |
| 📄 **Insurance Upload** | Upload and manage employee insurance documents |
| 🏖️ **Leave Apply** | Apply and track leave requests |
| 🚗 **Vehicle Tracking** | Track company vehicle usage |
| 🧑‍💼 **Self Service Portal** | Employee self-service for HR requests |
| ⏱️ **Overtime Management** | Log and manage employee overtime |
| 📊 **Manpower Dashboard** | Workforce analytics and insights |
| 👔 **Applicants** | Manage job applicants and hiring pipeline |

---

## 🛠️ Tech Stack

### 📱 Frontend — Flutter
```
Flutter 3.x (Dart)
├── State Management    → GetX
├── HTTP Client         → http package
├── WebSocket           → stomp_dart_client
├── Local DB            → sqflite
├── Notifications       → flutter_local_notifications
├── Env Config          → flutter_dotenv
└── Shared Prefs        → shared_preferences
```

### ⚙️ Backend — Spring Boot
```
Spring Boot 3.x (Java 17)
├── REST API            → Spring Web (Controllers)
├── Database ORM        → Spring Data JPA + Hibernate
├── Real-time Chat      → Spring WebSocket (STOMP)
├── Security            → API Key Authentication (X-API-KEY)
├── Database            → Oracle DB (OracleDriver)
├── File Handling       → Spring Multipart (10MB max)
└── Architecture        → Controller → Service → Repository → Entity
```

### 🗄️ Database
```
Oracle Database
├── Host     → 192.168.x.x:1521
├── Schema   → Employee, Insurance, Chat, Notifications, Attendance
└── DDL      → Hibernate auto-update
```

---

## 📁 Project Structure

```
App/
├── 📱 HEG/                          ← Flutter App
│   ├── lib/
│   │   ├── data/
│   │   │   ├── insurance_api.dart
│   │   │   ├── insurance_db.dart
│   │   │   ├── notification_store.dart
│   │   │   └── session_store.dart
│   │   ├── models/
│   │   │   └── employee.dart
│   │   ├── screens/
│   │   │   ├── home_page.dart
│   │   │   ├── attendance_page.dart
│   │   │   ├── employee_details_page.dart
│   │   │   ├── employees_page.dart
│   │   │   ├── insurance_upload_page.dart
│   │   │   ├── leave_apply_page.dart
│   │   │   ├── login_page.dart
│   │   │   ├── notifications_page.dart
│   │   │   ├── manpower_dashboard_page.dart
│   │   │   ├── overtime_management_page.dart
│   │   │   ├── profile_page.dart
│   │   │   ├── self_service_portal_page.dart
│   │   │   └── vehicle_tracking_page.dart
│   │   ├── services/
│   │   │   ├── chat_service.dart       ← WebSocket + REST chat
│   │   │   └── notification_service.dart
│   │   ├── widgets/
│   │   │   ├── chat_bubble_button.dart
│   │   │   └── notification_bell.dart
│   │   └── main.dart
│   └── android/
│       └── app/src/main/AndroidManifest.xml
│
└── ⚙️ backend/demo/                  ← Spring Boot API
    └── src/main/java/com/example/demo/
        ├── chat/                      ← WebSocket STOMP chat
        ├── controller/                ← REST API endpoints
        ├── dto/                       ← Data Transfer Objects
        ├── entity/                    ← JPA Entities (Oracle tables)
        ├── insurance/                 ← Insurance module
        ├── security/                  ← API Key security filter
        ├── service/                   ← Business logic
        └── DemoApplication.java
```

---

## 🔐 Security

- All API calls are protected via **`X-API-KEY`** header authentication
- API key is stored **only on the backend** (`application.properties`) — never exposed to the client
- Flutter app sends requests to the Spring Boot backend which internally manages all API keys
- Role-based views: **Admin** sees all employees' chats; **Employee** sees only their own

---

## 💬 Real-time Chat Architecture

```
Flutter (Employee)                Spring Boot Backend              Flutter (Admin)
      │                                   │                               │
      │──── WebSocket CONNECT ───────────▶│                               │
      │──── STOMP SUBSCRIBE ─────────────▶│◀──── STOMP SUBSCRIBE ─────────│
      │                                   │                               │
      │──── Send Message ────────────────▶│──── Broadcast to Admin ──────▶│
      │                                   │                               │
      │◀─── Polling fallback (8s) ────────│                               │
```

- Primary: **WebSocket (STOMP)** for instant delivery
- Fallback: **HTTP polling** every 8 seconds for reliability
- Unread badge tracking with `ValueNotifier`
- Push notifications via `flutter_local_notifications`

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x
- Java 17+
- Oracle Database
- Android Studio / VS Code

### 1️⃣ Clone the Repository
```bash
git clone https://github.com/anchitchourasia/App.git
cd App
```

### 2️⃣ Backend Setup
```bash
cd backend/demo

# Configure your Oracle DB in:
# src/main/resources/application.properties
# Set: spring.datasource.url, username, password

./mvnw spring-boot:run
# Backend starts on http://localhost:8080
```

### 3️⃣ Flutter App Setup
```bash
cd HEG

# Create .env file
echo "BASE_URL=http://10.0.2.2:8080" > .env

# Install dependencies
flutter pub get

# Run on emulator
flutter run
```

---

## 📡 API Overview

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/employees` | List all employees |
| `GET` | `/api/employees/{id}` | Get employee details |
| `GET` | `/api/insurance/notifications` | Get notifications |
| `POST` | `/api/insurance/upload` | Upload insurance document |
| `GET` | `/api/chat/history` | Fetch chat history |
| `WS` | `/ws` | WebSocket connection endpoint |
| `STOMP` | `/app/chat.send` | Send chat message |
| `STOMP` | `/topic/messages/{id}` | Subscribe to messages |

> All endpoints require `X-API-KEY` header

---

## ⚙️ Configuration

### `application.properties` (Backend)
```properties
app.api-key=YOUR_SECRET_KEY
spring.datasource.url=jdbc:oracle:thin:@//HOST:1521/DB
spring.datasource.username=USERNAME
spring.datasource.password=PASSWORD
spring.jpa.hibernate.ddl-auto=update
spring.servlet.multipart.max-file-size=10MB
```

### `.env` (Flutter)
```env
BASE_URL=http://10.0.2.2:8080
```

---

## 👨‍💻 Developer

<div align="center">

**Anchit Chourasia**

[![GitHub](https://img.shields.io/badge/GitHub-anchitchourasia-181717?style=flat-square&logo=github)](https://github.com/anchitchourasia)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Anchit_Chourasia-0A66C2?style=flat-square&logo=linkedin)](https://linkedin.com/in/anchit-chourasia-65b603226)

</div>

---

<div align="center">

**HEG HRMS** — Built with ❤️ using Flutter & Spring Boot

</div>
]]>