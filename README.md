# Fahamni — Private Tutoring Platform

> **2CP End-of-Year Project — École Nationale Supérieure d'Informatique (ESI), Algiers**  
> Lead Developer: **Mahieddine Mohamed Mimoun**

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-^3.11-0175C2?logo=dart&logoColor=white)
![React](https://img.shields.io/badge/React-19-61DAFB?logo=react&logoColor=black)
![Vite](https://img.shields.io/badge/Vite-8-646CFF?logo=vite&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-12-FFCA28?logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-green)

**Fahamni** ("understand me" in Arabic) is a full-stack private tutoring marketplace built as a 2CP graduation project at ESI Algiers. Students find and book certified tutors, parents monitor their children's learning, and a React web dashboard lets administrators manage the whole platform — all powered by Firebase and an embedded AI study assistant.

I was the lead developer on this project, responsible for the entire admin web dashboard, the AI assistant integration, the quote/estimate PDF system, Firebase infrastructure, and the multilingual (EN/FR/AR) interface.

---

## Table of Contents

- [Features](#features)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Installation](#installation)
  - [Mobile App (Flutter)](#mobile-app-flutter)
  - [Admin Web Dashboard (React)](#admin-web-dashboard-react)
- [Usage](#usage)
- [Configuration](#configuration)
- [Dependencies](#dependencies)
- [Team](#team)
- [Contributing](#contributing)
- [License](#license)

---

## Features

### Mobile App
- **Multi-role authentication** — Email/password, Google Sign-In, SMS OTP, and email OTP for students, tutors, and parents.
- **Teacher onboarding & approval** — Tutors upload certification files during registration; the account stays in `pending` state until an admin validates it.
- **Map-based service discovery** — Students and parents browse available tutoring services on an interactive Google Maps screen, with geolocation and routing.
- **Tutoring services** — Tutors create named services with subject, level, mode (in-person / online), price, and availability.
- **Session scheduling** — Students book sessions, tutors accept or decline; sessions are tracked with status and history.
- **Real-time messaging** — Group and direct conversations with text, images, audio messages, file attachments, and media galleries.
- **AI Study Assistant** — A slide-up sheet inside any tutor conversation lets students ask Claude (Anthropic) or Gemini to summarise the chat, generate practice questions, simplify tutor messages, or explain concepts. The provider and model are switchable via `.env`.
- **Quote & estimate system** — Students request a price quote from a tutor; tutors respond with a formal estimate that can be exported as a PDF.
- **Feedback & ratings** — Students leave star reviews for tutors after sessions.
- **Push notifications** — In-app notification centre backed by a Firestore `notifications` collection.
- **Suspended-account gate** — Suspended users see a dedicated screen explaining their status instead of reaching the main UI.
- **Parent dashboard** — Parents track their linked children's schedules, tutors, and courses; can explore services on behalf of a child.
- **Courses** — Tutors organise enrolled students into courses with sessions, members, and shared resources (files / links).

### Admin Web Dashboard *(built by me)*
- **Teacher validation workflow** — Review pending tutor applications, inspect credentials, validate or reject with a reason.
- **User management** — Browse and search students, tutors, and parents; view full profiles; suspend or reinstate accounts.
- **Reports management** — Triage session and behaviour reports submitted by users.
- **Admin messaging** — Open a conversation with any user directly from their profile.
- **Statistics** — Charts (Recharts) for user growth, session trends, tutor activity, and revenue.
- **Real-time notifications** — Live Firestore listeners push new tutor applications and pending reports to the bell icon without a page refresh.
- **Multilingual UI** — English, French, and Arabic with full RTL document direction switching.
- **Admin settings** — Profile editing and language preference persisted in Firestore and `localStorage`.

---

## Project Structure

```
Fahamni/
├── fahamni/
│   ├── mobile/                         # Flutter cross-platform mobile app
│   │   ├── lib/
│   │   │   ├── main.dart               # Entry point; AuthGate routes by role
│   │   │   ├── firebase_options.dart   # Generated Firebase config (per-platform)
│   │   │   ├── models/                 # Dart data classes
│   │   │   │   ├── user_model.dart     # Abstract base; factory dispatches to sub-types
│   │   │   │   ├── student_model.dart
│   │   │   │   ├── tutor_model.dart    # Includes expertise, rating, certification fields
│   │   │   │   ├── parent_model.dart
│   │   │   │   ├── chat_model.dart     # ConversationModel + MessageModel
│   │   │   │   ├── service_model.dart
│   │   │   │   ├── session_model.dart
│   │   │   │   ├── notification_model.dart
│   │   │   │   ├── quote_model.dart
│   │   │   │   ├── resource_model.dart
│   │   │   │   ├── review_model.dart
│   │   │   │   └── ai_message.dart     # AI chat history entry
│   │   │   ├── Services/               # Business logic & Firebase wrappers
│   │   │   │   ├── auth_.service.dart          # Sign-up, sign-in, Google, OTP, certification upload
│   │   │   │   ├── ai_service.dart             # Claude / Gemini streaming AI assistant
│   │   │   │   ├── chat_service.dart           # Conversation CRUD, messaging
│   │   │   │   ├── notification_service.dart   # In-app push notifications
│   │   │   │   ├── session_service.dart        # Session lifecycle
│   │   │   │   ├── services_service.dart       # Tutor service listings
│   │   │   │   ├── student_tutor_action_service.dart  # Booking, request flows
│   │   │   │   ├── review_service.dart
│   │   │   │   ├── ressource_service.dart
│   │   │   │   ├── admin_support_chat_service.dart
│   │   │   │   ├── email_otp_service.dart
│   │   │   │   ├── phone_auth_service.dart
│   │   │   │   ├── parent_child_service.dart
│   │   │   │   ├── guest_mode_service.dart
│   │   │   │   └── suspended_account_gate.dart
│   │   │   ├── repositories/           # Data-access layer abstraction
│   │   │   │   ├── chat_repository.dart
│   │   │   │   ├── firestore_chat_repository.dart
│   │   │   │   ├── review_repository.dart
│   │   │   │   └── firestore_review_repository.dart
│   │   │   ├── navigation/
│   │   │   │   └── app_navigation.dart  # Singleton NavigationService + fade route builder
│   │   │   ├── messaging/              # All chat UI
│   │   │   │   ├── conversation_page.dart
│   │   │   │   ├── chat_page.dart
│   │   │   │   ├── message_bubble.dart
│   │   │   │   ├── Message_input.dart       # Rich input: text, image, audio, file
│   │   │   │   ├── ai_assistant_sheet.dart  # Slide-up AI panel
│   │   │   │   ├── ai_study_chat_page.dart
│   │   │   │   └── admin_support_chat_page.dart
│   │   │   ├── StudentHomePage/
│   │   │   ├── TeacherDashboard/
│   │   │   ├── ParentDashboread/
│   │   │   ├── Courses/
│   │   │   ├── Explore_map_pages/
│   │   │   ├── estimate/               # Quote request, estimate builder, PDF export
│   │   │   ├── feedback/
│   │   │   ├── Login_Screen/
│   │   │   ├── Onboarding/
│   │   │   ├── Notification_page/
│   │   │   ├── Account_Settings_Student/
│   │   │   ├── Account_Settings_Teacher/
│   │   │   ├── Account_Settings_Parent/
│   │   │   ├── User_status/
│   │   │   ├── utils/
│   │   │   └── widgets/
│   │   ├── firestore.rules
│   │   ├── storage.rules
│   │   ├── functions/
│   │   ├── assets/
│   │   └── pubspec.yaml
│   │
│   └── web/                            # React admin dashboard (built by me)
│       ├── src/
│       │   ├── main.jsx
│       │   ├── App.jsx                 # Firebase Auth gate
│       │   ├── Dashboard.jsx           # Shell layout + routing state machine
│       │   ├── Login.jsx
│       │   ├── TeachersPage.jsx
│       │   ├── TeacherProfilePage.jsx
│       │   ├── UsersPage.jsx
│       │   ├── UserProfilePage.jsx
│       │   ├── ReportsPage.jsx
│       │   ├── MessagesPage.jsx
│       │   ├── StatisticsPage.jsx
│       │   ├── SettingsPage.jsx
│       │   ├── ServiceDetailPanel.jsx
│       │   ├── firebase.js
│       │   ├── i18n.js                 # i18next + RTL switching
│       │   └── locales/
│       │       ├── en.json
│       │       ├── fr.json
│       │       └── ar.json
│       ├── package.json
│       └── vite.config.js
│
├── Instalation web/                    # Static landing page
├── android/ ios/ linux/ macos/ windows/
├── .env.example
└── package.json
```

---

## Architecture

### Data Model & Firestore Collections

All data lives in **Cloud Firestore**. The schema uses separate top-level collections per role:

| Collection | Purpose |
|---|---|
| `users` | Lightweight auth lookup: `uid`, `email`, `role`, `account_status`, `is_suspended` |
| `students` | Full student profiles |
| `tutors` | Tutor profiles including `expertise_domain`, `certification_url`, `account_status` (`pending` / `validated` / `rejected`), `average_rating` |
| `parents` | Parent profiles with child links |
| `admins` | Admin accounts; presence in this collection grants admin Firestore privileges |
| `conversations` | Chat threads; `participants[]` list drives access control |
| `messages` | Sub-collection under each conversation |
| `notifications` | In-app notifications consumed by the mobile notification centre |
| `services` | Tutor service listings |
| `sessions` | Booked sessions with status lifecycle |
| `reports` | User-submitted reports on sessions or behaviour |
| `reviews` | Star ratings tied to tutor + student + session |

**Firestore security rules** (`fahamni/mobile/firestore.rules`) encode the permission model: `isAdmin()` checks for a document in `admins/` under the caller's UID; conversation access uses `participants[]` membership; tutors own their services and sessions via `tutor_id` field checks.

### Mobile Auth Flow

`main.dart → AuthGate._checkAuth()`:

1. If no Firebase user → show `OnboardingScreen` (first run) or `LoginScreen`.
2. If logged in → fetch `users/{uid}` for `role` and `is_suspended`.
3. Fetch the role-specific profile document to double-check `is_suspended`.
4. Dispatch to the correct home screen:
   - `student` → `Studenthomepage`
   - `tutor` + `pending` → `TeacherGuestDashboardScreen`
   - `tutor` + `validated` → `TeacherDashboardScreen`
   - `parent` → `Parenthomepage`
   - Any + `is_suspended == true` → `SuspendedAccountGate.accountScreenForRole(role)`

### AI Study Assistant

`AIService` (`lib/Services/ai_service.dart`) streams responses token-by-token from either **Anthropic Claude** or **Google Gemini**, selected at runtime via `AI_PROVIDER` in `.env`.

The system prompt is dynamically constructed from:
- The student's `StudyLevel` (primary / secondary / university) — adjusts vocabulary and depth.
- The `AITaskType` (summarise, practice question, simplify, explain, smart reply, general help) — adjusts the task instruction.
- An injected transcript of the real tutor conversation as context.

The service first attempts a **streaming** HTTP request; if streaming fails (e.g. browser CORS restrictions), it falls back to a non-streaming POST and simulates streaming by yielding words with 15 ms delays.

Model selection is task-aware: `explainConcept` uses the "large" model; all other tasks use the "small" model — both configurable in `.env`.

### Admin Web Dashboard

`Dashboard.jsx` is a **single-component state machine**: all pages share a common `active` string (`"dashboard"`, `"teachers"`, `"users"`, …). Page components are conditionally rendered — no router library needed. Error boundaries (`PageErrorBoundary`) wrap each page so a crash in one section doesn't bring down the whole shell.

Real-time notifications arrive via two `onSnapshot` listeners (pending tutors + pending reports) that run for the lifetime of the session. Read state is stored in `localStorage` under a per-admin key.

The i18n system (`src/i18n.js`) uses **react-i18next** with three locale bundles (EN / FR / AR). Switching to Arabic also flips `document.documentElement.dir` to `"rtl"`. The admin's language preference is stored in their Firestore document and applied on login.

---

## Installation

### Prerequisites

- Flutter SDK ≥ 3.11 and Dart SDK ≥ 3.11
- Node.js ≥ 18 and npm
- A Firebase project with Firestore, Auth, Storage, and Functions enabled
- (Optional) Anthropic API key or Google Gemini API key for AI features

---

### Mobile App (Flutter)

```bash
# 1. Clone the repository
git clone https://github.com/YOUR_USERNAME/Fahamni.git
cd Fahamni/fahamni/mobile

# 2. Install Flutter dependencies
flutter pub get

# 3. Configure Firebase
# Place your google-services.json in android/app/
# Place your GoogleService-Info.plist in ios/Runner/

# 4. Create your .env file for AI features (optional)
cp ../../.env.example .env
# Fill in ANTHROPIC_API_KEY or GEMINI_API_KEY

# 5. Run on a connected device or emulator
flutter run
```

> **Note:** The app uses `firebase_app_check` with `AndroidProvider.debug` — suitable for development. Switch to `AndroidProvider.playIntegrity` for production builds.

---

### Admin Web Dashboard (React)

```bash
cd fahamni/web

# 1. Install dependencies
npm install

# 2. Configure Firebase
# Edit src/firebase.js with your Firebase project credentials

# 3. Start the development server
npm run dev
# → http://localhost:5173

# 4. Production build
npm run build
```

---

## Usage

### Running the Mobile App

```bash
cd fahamni/mobile

# Debug on Android
flutter run -d android

# Debug on iOS
flutter run -d ios

# Release APK
flutter build apk --release
```

### Running the Admin Dashboard

```bash
cd fahamni/web
npm run dev
```

Navigate to `http://localhost:5173`. Log in with an admin account — the user's UID must exist in the `admins` Firestore collection.

### Seeding Test Data

```bash
# From fahamni/web/
node seed-test-data.cjs          # General seed
node seed-rejected-teachers.cjs  # Seed teachers with rejected status
node seed_last_login.cjs         # Backfill last_login timestamps
node migrate-is-suspended.cjs    # Migration: add is_suspended to existing docs
```

> Requires `serviceAccountKey.json` (Firebase Admin SDK private key) in the same directory. **Do not commit this file.**

---

## Configuration

### Mobile App — `.env`

Place at `fahamni/mobile/.env` (copy from `.env.example`):

| Variable | Default | Description |
|---|---|---|
| `AI_PROVIDER` | `anthropic` | AI backend: `anthropic` or `gemini` |
| `ANTHROPIC_API_KEY` | — | Your Anthropic API key |
| `ANTHROPIC_SMALL_MODEL` | `claude-3-5-haiku-latest` | Fast tasks (summarise, smart reply, practice Q) |
| `ANTHROPIC_LARGE_MODEL` | `claude-3-7-sonnet-latest` | Deep tasks (explain concept) |
| `GEMINI_API_KEY` | — | Your Google Gemini API key |
| `GEMINI_SMALL_MODEL` | `gemini-2.5-flash` | Gemini fast model |
| `GEMINI_LARGE_MODEL` | `gemini-2.5-pro` | Gemini deep model |

If `.env` is absent the app starts normally — AI features are simply unavailable.

### Firestore Security Rules

Deploy with:

```bash
firebase deploy --only firestore:rules
```

---

## Dependencies

### Mobile (Flutter / Dart)

| Package | Purpose |
|---|---|
| `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage` | Core Firebase SDK |
| `firebase_app_check` | App attestation |
| `cloud_functions` | Server-side logic via Firebase Functions |
| `google_sign_in` | OAuth login via Google account |
| `google_maps_flutter` | Interactive map for service discovery |
| `geolocator`, `geocoding`, `flutter_polyline_points` | Location and routing |
| `http` | Streaming HTTP requests to AI APIs |
| `flutter_dotenv` | Loads `.env` at startup |
| `record`, `just_audio` | Audio message recording and playback |
| `file_picker`, `image_picker` | Attachment and camera access |
| `pdf`, `printing` | Quote/estimate PDF generation |
| `flutter_markdown`, `flutter_math_fork` | Render AI responses with Markdown and LaTeX |
| `cached_network_image` | Remote image caching |
| `shared_preferences` | Local persistence |
| `intl` | Date/time formatting |
| `permission_handler` | Runtime permissions |

### Web (React / Node)

| Package | Purpose |
|---|---|
| `react` + `react-dom` v19 | UI library |
| `firebase` v12 | Firestore and Auth client SDK |
| `i18next` + `react-i18next` | EN / FR / AR with RTL support |
| `recharts` | Statistics charts |
| `lucide-react` | Icon set |
| `vite` | Build tool and dev server |

---

## Team

This project was developed as a **2CP end-of-year project** at ESI Algiers by a team of six students.

| Name | Role |
|---|---|
| **Mahieddine Mohamed Mimoun** *(lead)* | Admin web dashboard, AI assistant, estimate/PDF system, Firebase infrastructure, i18n, deployment |
| Abdelmouname Meznaoui | Database models, messaging module, parent dashboard |
| Hamza Benrabah | Student homepage, teacher dashboard, notifications, schedule |
| Bedoui Wassim | Student backend page, Google Maps / explore, service UI |
| Aimed Benahmed | Mobile auth flows, SMS OTP |
| Alicia Messaoud | Status screens, initial user-info pages |

---

## Contributing

1. Fork the repository and create a branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. Run `flutter analyze` (mobile) or `npm run lint` (web) before committing.
3. Keep Firestore security rules in sync with any new collections you add.
4. Open a pull request with a clear description of the change.

---

## License

MIT License — see [LICENSE](LICENSE) for details.
