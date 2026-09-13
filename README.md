# NaijaMove Driver

Flutter app for NaijaMove drivers. All 10 flows from
`driver_app_design_prompt.md` are implemented on top of a data layer that talks
to the `server/` API; without a backend configured every repository returns
in-app mock data, so the whole app is navigable offline.

## Run

```bash
# Android emulator (host loopback is 10.0.2.2)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3004

# iOS simulator
flutter run --dart-define=API_BASE_URL=http://localhost:3004

# Mock mode — no backend
flutter run
```

## Screens (`lib/features`)

| Flow | Files |
|---|---|
| 1 Onboarding & auth | `onboarding/` — splash, carousel, phone, OTP, profile/vehicle/documents setup, under review, permissions |
| 2 Home | `home/` — dashboard (offline / online / pending / suspended), incoming request sheet, scheduled trips |
| 3 Active trip | `trip/` — one phase-driven screen (accepted → navigating → arrived + PIN → in progress + stops), completed, cancel, SOS, no-show, rider-cancelled, rider chat |
| 4 Earnings | `earnings/` — dashboard, wallet, trip detail, withdraw, bonuses, link bank, transactions |
| 5 Trips | `trips/` — history (live when a backend is set), cancelled-trip detail |
| 6 Profile | `profile/` — home, vehicle, emergency contact, safety, documents, public preview, settings, edit |
| 7 Notifications | `notifications/` |
| 8 Performance | `performance/` — my performance, Top Driver programme |
| 9 Support | `support/` — home, categories, form, submitted, cases, case chat, FAQ |
| 10 Offline | `offline/` |

`app/router.dart` wires them with go_router: a 4-tab `StatefulShellRoute`
(Home · Trips · Earnings · Profile) plus full-screen routes for the trip flow.
`--dart-define=START_ROUTE=/home` skips the splash for demos.

Trip state lives in `features/trip/trip_state.dart`: `activeTripProvider`
drives the phases and streams GPS over the trip channel; `incomingOfferProvider`
polls `/dispatch/offers/me` while online (mock mode fires a demo request 4 s
after going online).

## Tests

`flutter test` runs wire-model parsing tests and a smoke suite that pumps every
screen at phone size and fails on any exception (including layout overflow),
plus a walk through the active-trip phases.

## Data layer (`lib/data`)

| File | Role |
|---|---|
| `api/api_config.dart` | `API_BASE_URL`, WebSocket base, timeouts |
| `api/api_client.dart` | Dio wrapper: bearer auth, single-flight refresh on 401, `TokenStore` (flutter_secure_storage) — same contract as the rider app |
| `api/wire.dart` | Models 1:1 with server responses (`DriverAccount`, `TripOffer`, `DriverTrip`, `Earnings`, …) |
| `api/trip_channel.dart` | `/ws/trip/:id/driver` — authenticated with `?token=`, streams GPS + state |
| `repositories/auth_repository.dart` | OTP sign-in, `registerAsDriver()`, logout |
| `repositories/driver_repository.dart` | `/drivers/me`, availability, location, earnings, documents |
| `repositories/trips_repository.dart` | offers, accept/decline, arrive, start (PIN), complete, cancel, rate, history |
| `repositories/wallet_repository.dart` | balance, transactions, withdraw |
| `app/state/session.dart` | `SessionStage` funnel: signedOut → needsDriverProfile → awaitingApproval → active |

## Sign-in funnel

Every account starts as a `rider`. The flow the onboarding screens must drive:

1. `requestOtp(phone)` → `verifyOtp(phone, code)` — returns `LoginResult.role`.
2. If `role == 'rider'`: call `registerAsDriver()`. The server creates the driver
   profile, switches the account role, and returns a **new token pair** carrying
   `role: driver`; the repository stores it automatically.
3. Read `/drivers/me`. `DriverAccountStatus.canGoOnline` is only true once an
   admin has approved the profile — until then, show the document/review state.
4. Going online (`setOnline(true)`) returns 403 for unapproved accounts.

## Trip lifecycle

```
pendingOffers() → acceptOffer(offerId) → tripId
  → DriverTripChannel(tripId).connect()   // GPS every ~3 s
  → arrived(tripId)
  → startWithPin(tripId, pin)             // rider reads their 4-digit PIN; 5 wrong = locked
  → complete(tripId, distance, duration)
  → rateRider(tripId, rating)
```

The server closes the WebSocket when the trip ends; `DriverTripChannel.done`
resolves then.
