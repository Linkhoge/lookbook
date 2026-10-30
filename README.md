# LookBook


A student-focused outfit and campus-style application built with Flutter and Firebase.

**Author:** Linkhoge
**Status:** First iteration — academic prototype

## Development notes

See [NOTES.md](NOTES.md) for known issues and planned work.

## Overview

This iteration includes Firebase authentication, a campus feed, profile screens,
demo social interactions, a challenges section, and in-app test notifications.

Some features use placeholder content or session-based demo data. Upload,
Wardrobe, and Lookbook functionality are still in development.

## Requirements

- Flutter SDK
- Git
- Google Chrome

## Setup

Clone the repository:

```bash
git clone [https://github.com/Linkhoge/lookbook.git](https://github.com/Linkhoge/lookbook.git)
cd lookbook
```

From the folder containing `pubspec.yaml`, install dependencies and run:

```bash
flutter pub get
flutter run -d chrome
```

If the Flutter application is inside a subfolder, navigate into it first.

## Firebase

The application uses Firebase Authentication and requires an internet connection
and valid Firebase client configuration.

Sign in or register through the application. Any assessment credentials will
be supplied separately.