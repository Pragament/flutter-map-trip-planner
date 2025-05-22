# Flutter Map Trip Planner

## Screenshots

Below are screenshots demonstrating key features and recent changes. Please ensure you add relevant screenshots for every pull request as per the [Contributing Guidelines](#contributing-guidelines).

| Login Screen                | All Routes Map Screen         | Route Details Screen         |
|----------------------------|------------------------------|-----------------------------|
| ![Login Screen](screenshots/feature-login.png) <br> *User authentication via phone number* | ![All Routes](screenshots/feature-allroutes.png) <br> *Overview of all user routes on the map* | ![Route Details](screenshots/feature-route-details.png) <br> *Detailed view of a selected route* |

<!-- Add more screenshots as needed, following the above format. -->
<img src="https://github.com/user-attachments/assets/12aef0c1-21d5-4570-a087-a80ce5d092f5" width="300" height="600" alt="App Screenshot 1" />
<img src="https://github.com/user-attachments/assets/11b069d0-fd48-4fd1-a150-7b8f39188992" width="300" height="600" alt="App Screenshot 2" />
<img src="https://github.com/user-attachments/assets/d522301e-e646-41e2-a7d5-313fe9339cb6" width="300" height="600" alt="App Screenshot 3" />
<img src="https://github.com/user-attachments/assets/e2159cbb-2ead-42fa-bc48-e9ae870852fc" width="300" height="600" alt="App Screenshot 4" />
<img src="https://github.com/user-attachments/assets/84b1dfbe-ba0b-4e38-9c87-7426a8c5a0db" width="300" height="600" alt="App Screenshot 5" />

---

## Project Description

Flutter Map Trip Planner is a mobile application that helps users plan, manage, and get reminders for their trips and routes. It integrates with Firebase for authentication and data storage, and uses local notifications to remind users about upcoming trips.

## Features

- User authentication via phone number (Firebase Auth)
- View, add, and manage multiple routes
- Route details with dates and locations
- Local notifications for upcoming trips
- Persistent user sessions and data storage (Firebase Firestore)
- Responsive UI with Material Design
- Overlay support for quick access (optional/experimental)

## Project Overview for New Contributors

This project is structured to separate concerns between UI, state management, and backend integration. Here’s a high-level overview:

### Major Folders

- **lib/**: Main source code for the Flutter app.
  - **models/**: Data models (e.g., `event.dart`).
  - **providers/**: State management using Provider (e.g., `event_provider.dart`, `route_provider.dart`).
  - **screens/**: UI screens (e.g., `all_routes.dart`, `login.dart`, `route_display_screen.dart`).
  - **widgets/**: Reusable UI components (e.g., `local_notifications.dart`, `route_table.dart`).
- **screenshots/**: Screenshots for documentation and PRs.
- **firebase_options.dart**: Firebase configuration (auto-generated).
- **pubspec.yaml**: Project dependencies and assets.

### Important Files

- **main.dart**: Entry point, app initialization, notification logic, and route setup.
- **firebase_options.dart**: Firebase setup (do not edit manually).
- **pubspec.yaml**: Lists dependencies and assets.

### Architecture & Component Interaction

- **Frontend**: Built with Flutter, using Provider for state management.
- **Backend**: Firebase Auth for authentication, Firestore for data storage.
- **Notifications**: Local notifications for reminders, with permission handling.
- **Data Flow**: User actions trigger provider updates, which update Firestore and UI. Notifications are scheduled based on route dates.

### How Components Interact

- **User logs in** → Auth state managed by Firebase Auth.
- **Routes loaded** from Firestore based on user ID.
- **Providers** manage app state and notify UI of changes.
- **Notifications** scheduled if a route is due today.

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- A Firebase project (with Auth and Firestore enabled)
- Android/iOS device or emulator

### Setup Steps

1. **Clone the repository:**
   ```sh
   git clone https://github.com/yourusername/flutter-map-trip-planner.git
   cd flutter-map-trip-planner
   ```

2. **Install dependencies:**
   ```sh
   flutter pub get
   ```

3. **Configure Firebase:**
   - Download your `google-services.json` (Android) and/or `GoogleService-Info.plist` (iOS) from the Firebase Console.
   - Place them in the appropriate platform folders (`android/app/`, `ios/Runner/`).

4. **Run the app:**
   ```sh
   flutter run
   ```

5. **(Optional) Set up local notifications permissions:**
   - Grant notification permissions on your device/emulator when prompted.

---

## Roadmap

- [ ] Add support for collaborative trip planning
- [ ] Integrate map-based route editing
- [ ] Improve offline support
- [ ] Add more notification customization
- [ ] Enhance UI/UX for accessibility

---

## Contributing Guidelines

We welcome contributions! Please follow these steps:

1. **Fork the repository and create your branch:**
   ```sh
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes and commit:**
   - Ensure your code follows the existing style and conventions.
   - Add or update tests if applicable.

3. **Add relevant screenshots:**
   - Take screenshots showing your changes.
   - Save them in the `screenshots/` folder.
   - Name them clearly (e.g., `feature-login.png`, `fix-navbar-bug.png`).

4. **Update the Screenshots section in the README:**
   - Add your new screenshots to the table with appropriate captions/context.

5. **Open a pull request:**
   - Describe your changes and reference any related issues.
   - Ensure your PR includes the updated screenshots.

6. **Wait for review and feedback.**

---

## Contributing

See [Contributing Guidelines](#contributing-guidelines) above for detailed instructions.

---

## License

This project is licensed under the [GNU Affero General Public License v3.0](LICENSE).

---

### Phone Numbers for Testing:

| Phone Number       | OTP    |
|--------------------|--------|
| <b>+91 12345 67890    | 111111 |
| <b>+91 98765 43210    | 111111 |

## Code build instructions
1. Copy .env.example file as .env
2. If you need GOOGLE_PLACES_API_KEY or GRAPHHOPPER_API_KEY message author in whatsapp
3. ```dart run build_runner build```

## For firebase login related Code build instructions
1. https://developers.google.com/android/guides/client-auth ```keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore```![image](https://github.com/user-attachments/assets/aac7528a-fb52-4131-8d0f-64782b5d6af9)
2. send your SHA1 key in whatsapp to repo author to add your device to company firebase account for debugging.
