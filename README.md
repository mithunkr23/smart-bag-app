# Smart Bag System

An intelligent mobile app that verifies whether required books are packed based on a timetable using RFID tags scanning and sends alerts if any are missing.

## Features
- Real-time RFID tag scanning (multi-scan)
- Detects required vs detected books
- Shows missing books
- Handles unknown barcodes
- SMS alerts (Twilio)

## Tech Stack
- Flutter (Dart)
- mobile_scanner
- HTTP (Twilio API)

## How it works
1. User taps **Scan Books**
2. App scans multiple books for ~10 seconds
3. Matches detected subjects with today’s timetable
4. Shows **Detected** and **Missing**
5. Sends SMS alert if needed

## Setup
```bash
flutter pub get
flutter run
