# Runs the end-to-end test on a running Android emulator.
#
# Before running this, start the Firebase emulators in another window:
#   firebase emulators:start --only auth,firestore

$ErrorActionPreference = 'Continue'
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:ANDROID_HOME = 'C:\dev\android-sdk'
$env:PUB_CACHE = 'C:\dev\pub-cache'
$env:PATH = "C:\Program Files\Git\cmd;C:\dev\flutter\bin;C:\dev\android-sdk\platform-tools;$env:PATH"

Set-Location (Split-Path $PSScriptRoot -Parent)

# The emulator's stylus tutorial and on-screen keyboard cover the app while
# the test types, so they are switched off for the test device.
adb shell settings put secure stylus_handwriting_enabled 0
adb shell settings put secure show_ime_with_hard_keyboard 0
adb shell am force-stop com.creba.creba_connect
Start-Sleep -Seconds 2

flutter test integration_test/app_test.dart `
  -d emulator-5554 `
  --dart-define=USE_FIREBASE_EMULATOR=true 2>&1 |
  Tee-Object -FilePath (Join-Path $env:TEMP 'creba-e2e.log')
