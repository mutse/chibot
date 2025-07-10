#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
flutter pub get
flutter pub global activate msix
flutter pub run msix:build