# ♻️ GreenMachine — Smart Recycling Machine Admin Dashboard

**GreenMachine** is a cross-platform Flutter admin dashboard for monitoring and managing a fleet of Reverse Vending Machines (RVMs) deployed across Algeria. It provides real-time tracking, analytics, worker dispatch, and alert management — all from a single, premium interface.

---

## 📸 Features at a Glance

| Feature | Description |
|---|---|
| 🔐 **Secure Login** | Email/password authentication with forgot-password flow |
| 📊 **Dashboard** | Live stats (aluminum, plastic, machine count) + interactive OpenStreetMap |
| 🏭 **Machine Management** | Add, view details, update status (online/offline/broken), delete machines |
| 👷 **Worker Management** | Create, assign, and track technicians & bin-emptiers (videurs) |
| 📈 **Analytics** | Recycling trends, pie charts, bar charts by wilaya, KPI cards, critical alerts |
| 🔔 **Notifications** | Real-time alert system with worker assignment for breakdowns & fill-level warnings |
| ⚙️ **Settings** | Dark/Light theme, multi-language (🇫🇷 Français, 🇬🇧 English, 🇩🇿 العربية), password change |

---

## 🏗️ Architecture

The app follows a clean **Provider-based** state management pattern with a clear separation of concerns:

```
lib/
├── main.dart                  # App entry point & MultiProvider setup
├── models/
│   ├── dashboard_model.dart   # Dashboard stats model
│   ├── login_model.dart       # Authentication logic
│   ├── machinedata_model.dart # Machine data model
│   ├── settings_model.dart    # Settings data model
│   └── worker_model.dart      # Worker, roles & task models
├── pages/
│   ├── login_page.dart        # Login screen with premium UI
│   ├── dashboard_page.dart    # Main dashboard with map & stats
│   ├── machines_page.dart     # CRUD machine management
│   ├── worker_page.dart       # Worker management & dispatch
│   ├── analytics_page.dart    # Charts, KPIs & inventory
│   └── settings_page.dart     # Theme, language & security settings
├── providers/
│   ├── machine_provider.dart      # Machine API calls & state
│   ├── notification_provider.dart # Notification management
│   ├── settings_provider.dart     # Theme, locale & translations
│   └── worker_provider.dart       # Worker API calls & state
└── widgets/
    ├── sidebar.dart           # Collapsible navigation sidebar
    └── dashboard_header.dart  # Header with notifications
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter 3.10+ (Material 3) |
| **State Management** | Provider (`ChangeNotifier`) |
| **Maps** | `flutter_map` + OpenStreetMap tiles |
| **Charts** | `fl_chart` (Line, Bar, Pie) |
| **Geocoding** | `geocoding` + Nominatim OSM fallback |
| **Typography** | Google Fonts (Outfit, Inter, Readex Pro) |
| **HTTP** | `http` package |
| **Persistence** | `shared_preferences` |
| **Backend** | REST API hosted on [Render](https://render.com) |
| **Database** | MongoDB |

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.10
- Dart SDK ≥ 3.10
- Android Studio / VS Code with Flutter extension
- A physical device or emulator

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/benhadjbaferiel/GreenMachine.git
cd GreenMachine/recycle_app-main

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run
```

### Supported Platforms

| Platform | Status |
|---|---|
| 🌐 Web | ✅ Supported |
| 🤖 Android | ✅ Supported |
| 🍎 iOS | ✅ Supported |
| 🪟 Windows | ✅ Supported |
| 🐧 Linux | ✅ Supported |
| 🍏 macOS | ✅ Supported |

---

## 🗺️ Key Pages

### 🔐 Login
Premium split-screen login with form validation, show/hide password toggle, and forgot-password dialog. Responsive layout adapts for mobile and desktop.

### 📊 Dashboard
- **Stats cards**: Total aluminum (kg), total plastic (kg), machine count
- **Interactive map**: Live markers colored by machine status (🟢 Online, 🟠 Offline, 🔴 Broken)
- **Notifications bell**: Badge with unread count, assign workers to alerts

### 🏭 Machines
- Machine table with search & status filters (All / Online / Offline / Broken)
- Add machine dialog with geo-coded location (auto-resolves city & address from coordinates)
- Detail modal with full machine info, photo link, AI accuracy, and status management
- Per-machine alert history with type filtering

### 👷 Workers
- Dashboard stats: total workers, technicians in intervention, available bin-emptiers, pending tasks
- Worker cards with avatar, role badge, status indicator, and action buttons
- Add/Delete workers with role selection and city assignment
- Profile bottom sheet & intervention history dialog

### 📈 Analytics
- KPI grid: Total machines, pending collections, plastic/aluminum weight with growth indicators
- Recycling trend line chart (7D / 14D / 30D / 90D periods)
- Distribution pie chart (PET vs ALU)
- Volume per wilaya bar chart
- Critical alerts list & detailed machine inventory table
- City filter dropdown with all 58 Algerian wilayas

### ⚙️ Settings
- Dark / Light theme toggle (persisted)
- Language switcher: Français, English, العربية
- Change password (calls backend API)

---

## 🔌 Backend API

The app communicates with a REST API hosted on Render:

```
Base URL: https://rvm-backend-oaot.onrender.com
```

| Endpoint | Method | Description |
|---|---|---|
| `/user/login` | POST | Authenticate admin |
| `/user/change-password` | PUT | Update password |
| `/machine/` | GET | List all machines |
| `/machine/create` | POST | Add a new machine |
| `/machine/:id` | GET | Machine details |
| `/machine/:id` | DELETE | Remove a machine |
| `/machine/:id/status` | PUT | Update machine status |
| `/machine/bin/update` | PUT | Update machine bin data |
| `/analytics` | GET | Analytics dashboard data |
| `/product/` | GET | Recycled products history |
| `/notification/pending` | GET | Pending notifications |
| `/notification/:id/assign` | PUT | Assign worker to alert |
| `/notification/:id/complete` | PUT | Close a notification |
| `/worker/` | GET | List all workers |
| `/worker/create` | POST | Add a worker |
| `/worker/:id` | DELETE | Remove a worker |
| `/worker/:id/status` | PUT | Update worker status |

---


The app supports **3 languages** with built-in translations:

- 🇫🇷 **Français** (default)
- 🇬🇧 **English**
- 🇩🇿 **العربية** (Arabic)

