🌐 SIH Project - Smart India Hackathon


📑 Table of Contents

Project Structure

About CivicConnect App

Features

Screens

Tech Stack

Getting Started

Testing

Development

Build & Deploy

Contributing

License

📂 Project Structure
<details> <summary>Click to expand project structure</summary>
SIH/
├── civicconnect_app/          # Main Flutter Application
│   ├── lib/                   # Dart source code
│   │   ├── main.dart         # App entry point
│   │   ├── models/           # Data models
│   │   ├── providers/        # State management
│   │   ├── screens/          # UI screens
│   │   └── widgets/          # Reusable UI components
│   ├── assets/               # App assets (images, fonts, etc.)
│   ├── android/              # Android platform code
│   ├── ios/                  # iOS platform code
│   ├── web/                  # Web platform code
│   └── pubspec.yaml          # Flutter dependencies
└── README.md                 # This file

</details>
📱 CivicConnect App

A Flutter application for reporting and tracking civic issues in your community.

✨ Features

🔐 User Authentication: Phone number + OTP login

📸 Report Issues: Submit civic issues with photos and location

📊 Track Reports: Monitor the status of submitted reports

🌍 Community View: See reports from other users

👤 Profile Management: Manage your profile and activity

🖼️ Screens
Login	Home	Report	Track	Profile

	
	
	
	

(Replace placeholders with your real screenshots/GIFs)

🛠️ Tech Stack

Framework: Flutter

State Management: Provider

Routing: GoRouter

Storage: SharedPreferences

UI: Material Design 3

🚀 Getting Started
✅ Prerequisites

Flutter SDK (3.4.0+)

Android Studio / VS Code

Emulator or physical device

⚡ Installation
cd SIH/civicconnect_app
flutter pub get
flutter run

🧪 Testing

Demo login: Any phone number + OTP 123456

Preloaded sample reports

Use hot reload (r) for quick development

🏗️ Development

Models → Data structures

Providers → State management

Screens → Full UI pages

Widgets → Reusable UI

📦 Build & Deploy

Android: flutter build apk --release

iOS: flutter build ios --release

Web: flutter build web --release

🤝 Contributing

Fork & clone repo

Create a feature branch (git checkout -b feature-name)

Commit changes (git commit -m "Add feature")

Push & open a PR 🚀
