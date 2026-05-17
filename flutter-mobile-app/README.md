# PulseLocal Flutter App

Flutter customer-facing checkout-risk screen for PulseLocal.

The mobile app must call Laravel only. It should not call the FastAPI ML service
directly.

## Environment

Create a local `.env` before running Flutter because `.env` is an app asset:

```powershell
copy .env.example .env
```

Default base URLs:

- Android emulator: `http://10.0.2.2:8000`
- Windows desktop: `http://127.0.0.1:8000`

Override at runtime:

```powershell
flutter run --dart-define=LARAVEL_BASE_URL=http://127.0.0.1:8000
```

## Run

```powershell
flutter pub get
flutter run
```

## Test

```powershell
flutter analyze
flutter test
```
