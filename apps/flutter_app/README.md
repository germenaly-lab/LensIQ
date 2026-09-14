# LensIQ Enterprise Flutter Application (Phase 5)

Cross-platform enterprise monitoring application supporting **Flutter Web**, **Android**, and **iOS**.

---

## 1. Project Architecture

The application is structured into clean architectural layers to enforce separation of concerns:

```
apps/flutter_app/lib/
├── config/
│   └── app_config.dart                  # Runtime URLs, Supabase credentials, demo flags
├── core/
│   ├── constants/
│   │   └── app_constants.dart           # Storage keys, breakpoints, demo credentials
│   ├── network/
│   │   └── api_client.dart              # Authenticated HTTP client with role headers
│   ├── theme/
│   │   ├── app_colors.dart              # Enterprise dark/light palette
│   │   ├── app_theme.dart               # Material 3 dark/light themes
│   │   └── app_typography.dart          # Dense, high-contrast typography
│   └── utils/
│       └── responsive_util.dart         # Responsive breakpoint utilities
├── features/
│   ├── auth/
│   │   └── login_screen.dart            # Supabase & instant demo role login
│   ├── cameras/
│   │   ├── camera_detail_screen.dart    # Live stream player & telemetry HUD
│   │   └── camera_list_screen.dart      # Multi-source cameras (RTSP / Hikvision P2P)
│   ├── dashboard/
│   │   ├── dashboard_screen.dart        # Role-aware operations dashboard
│   │   └── widgets/metric_card.dart     # KPI summary cards
│   ├── incidents/
│   │   └── incident_list_screen.dart    # AI detection events & cashier empty alerts
│   └── settings/
│       └── settings_screen.dart         # User identity, API config, theme toggle
├── models/
│   ├── camera.dart                      # CameraModel (RTSP vs Hikvision P2P)
│   ├── dashboard_summary.dart           # Dashboard KPI model
│   ├── incident.dart                    # AI detection incident model
│   ├── stream_session.dart              # Phase 4 unified stream session model
│   └── user_profile.dart                # UserProfile with UserRole enum
├── providers/
│   ├── auth_provider.dart               # Session, authentication, role switcher
│   ├── camera_provider.dart             # Multi-source inventory & live stream
│   ├── incident_provider.dart           # AI detections & dashboard KPIs
│   └── theme_provider.dart              # Dark/light theme mode
├── repositories/
│   ├── auth_repository.dart             # Auth repository abstraction
│   ├── camera_repository.dart           # Camera data & stream initiation
│   └── incident_repository.dart         # Incident data
├── routing/
│   ├── app_router.dart                  # GoRouter with role & auth guards
│   └── app_routes.dart                  # Route definitions
├── services/
│   ├── auth_service.dart                # Supabase Auth & session persistence
│   ├── mock_data_service.dart           # Phase 1-4 seed data & offline fallback
│   └── supabase_service.dart            # Resilient Supabase client wrapper
├── widgets/
│   ├── empty_state_view.dart            # Empty state view
│   ├── enterprise_sidebar.dart          # Desktop sidebar navigation
│   ├── error_view.dart                  # Error view with retry
│   ├── loading_view.dart                # Enterprise loading view
│   ├── responsive_scaffold.dart         # Responsive desktop sidebar / mobile navbar
│   ├── severity_badge.dart              # Incident severity badges
│   └── status_badge.dart                # Camera status & transport badges
└── main.dart                            # Application entrypoint
```

---

## 2. Authentication & Role-Based Authorization

### Supported User Roles:
1. **Super Admin** (`admin@lensiq.cloud`):
   * Full access to all tenant companies, retail brands, branches, and system metrics.
2. **Brand Manager** (`brand@ego.demo`):
   * Scoped to the retail brand (**Ego Fashion**), viewing store analytics, camera health, and cashier empty alerts.
3. **Branch Security** (`security@ego-moa.demo`):
   * Scoped to the specific physical branch (**Ego Mall of Arabia**), viewing live camera surveillance feeds, real-time alerts, and unattended counter alarms.

### Session Persistence:
* Stored in `SharedPreferences` (`lensiq_user_profile` and `lensiq_auth_token`).
* Restores active session on app refresh or restart.
* Automatically guarded via `GoRouter` redirect.

---

## 3. Multi-Source Streaming & Security Guarantee

* **Transport Abstraction**: Consumes the Phase 4 Streaming Gateway unified endpoints (`/api/v1/streams/:cameraId/session`).
* **Zero Credential Exposure**: The Flutter application **never** receives plaintext RTSP passwords or Hikvision AppKeys. Playback is mediated via ephemeral, signed HMAC session tokens.
* **Single Ingest Deduplication**: Multiple viewers watching the same camera share a single underlying pipeline on the gateway.

---

## 4. How to Run

### Run on Flutter Web:
```bash
flutter run -d chrome
```

### Build for Production:
```bash
# Web
flutter build web --release

# Android APK
flutter build apk --release

# Run Tests
flutter test

# Static Analysis
flutter analyze
```
