# La Pyramide 🔺🍺

Application mobile **iOS & Android** du jeu de cartes alcoolisé "La Pyramide", développée avec **Flutter (Dart)**.

## 🚀 Fonctionnalités

- 🃏 **Mode local** — jouez à plusieurs sur un seul téléphone
- 🌐 **Mode en ligne** — créez ou rejoignez une salle avec un code à 6 chiffres
- 😈 **Système de bluff complet** — challenge avec compte à rebours
- 🎨 **Design festif** — thème sombre, couleurs néon, animations fluides
- 🌍 **Bilingue** — Français 🇫🇷 et Anglais 🇬🇧
- ⚠️ **Disclaimer +18** — obligatoire pour les stores

## 🛠️ Tech Stack

| Élément | Technologie |
|---|---|
| Framework | Flutter 3.32 (Dart 3) |
| State | Riverpod |
| Navigation | GoRouter |
| Backend | Firebase Realtime DB |
| Auth | Apple + Google + Anonyme |
| Animations | flutter_animate + Lottie |
| Audio | audioplayers |

## 📦 Installation

```bash
# 1. Installer les dépendances
flutter pub get

# 2. Configurer Firebase
flutterfire configure --project=la-pyramide

# 3. Lancer en mode debug
flutter run

# 4. Build iOS
flutter build ios --release

# 5. Build Android
flutter build appbundle --release
```

## 🔧 Configuration Firebase requise

1. Aller sur [console.firebase.google.com](https://console.firebase.google.com)
2. Créer un projet **"la-pyramide"**
3. Activer **Authentication** (Google + Apple + Anonyme)
4. Activer **Realtime Database**
5. Lancer : `flutterfire configure --project=la-pyramide`

## 📁 Structure du projet

```
lib/
├── main.dart                   # Point d'entrée
├── firebase_options.dart       # Config Firebase (généré par flutterfire)
├── app/
│   ├── app.dart               # MaterialApp + Router + Localizations
│   ├── theme.dart             # Thème festif (couleurs, typo, gradients)
│   └── router.dart            # Routes GoRouter
├── features/
│   ├── splash/                # Écran disclaimer +18
│   ├── home/                  # Écran d'accueil
│   ├── auth/                  # Connexion Google/Apple/Anonyme
│   ├── lobby/                 # Lobbies local et en ligne
│   ├── game/
│   │   ├── models/            # Card, Player, GameState
│   │   ├── widgets/           # Pyramide, main, overlays
│   │   ├── local/             # Jeu local
│   │   └── online/            # Jeu en ligne (Phase 5)
│   ├── rules/                 # Règles du jeu
│   └── settings/              # Paramètres
├── l10n/
│   ├── app_fr.arb             # 🇫🇷 Traductions françaises
│   └── app_en.arb             # 🇬🇧 English translations
└── shared/
    └── widgets/               # Composants réutilisables
```

## 🗺️ Feuille de route

- [x] Phase 1 — Fondations (thème, routing, localization, disclaimer)
- [x] Phase 2 — Modèles de données et logique de jeu
- [x] Phase 3 — Interface pyramide et cartes
- [x] Phase 4 — Mode local complet
- [ ] Phase 5 — Mode en ligne Firebase
- [ ] Phase 6 — Audio + Animations Lottie
- [ ] Phase 7 — Écrans secondaires + polish
- [ ] Phase 8 — Publication App Store + Google Play
