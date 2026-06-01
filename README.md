# FocusPet

FocusPet is a Flutter Android mobile MVP for gamified study sessions. It stores progress locally on the device: timed sessions, XP, coins, pet level, daily streak, quests, basic stats, customization items, and notification preferences.

No ads, subscriptions, backend, account system, AI, leaderboard, or hard app blocking are included in this MVP.

## Implemented MVP

- `Home`: dashboard, today summary, pet preview, daily quests, reward claim.
- `Onboarding`: three introduction screens and a study buddy choice.
- `Focus`: setup screen, subjects, Normal/Deep Focus modes, a resumable timer, pause limits, cancellation confirmation, and completion rewards.
- `Pet`: profile, level progress, feed and rename actions, with equipped hats, room pieces, backgrounds, and effects shown on the buddy.
- `Stats`: today/week/best/streak cards, simple weekly bars, subject breakdown.
- `Shop`: item categories, buy/equip flow using coins.
- `Settings`: local notification permission, daily reminder time, dark mode, and progress reset.
- `Persistence`: completed progress and in-flight timers survive application restarts using local storage.

Pomodoro rounds and break flows are intentionally held out until that complete experience is implemented.

## Run on Android

Flutter `3.44.0` is installed locally at `C:\tools\flutter`, and the Android SDK is configured. With an emulator running or a phone attached:

```powershell
C:\tools\flutter\bin\flutter.bat run
```

To run checks or produce an APK:

```powershell
C:\tools\flutter\bin\flutter.bat analyze
C:\tools\flutter\bin\flutter.bat test
C:\tools\flutter\bin\flutter.bat build apk --debug
```
