import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'La Pyramide'**
  String get appName;



  /// No description provided for @home_title.
  ///
  /// In fr, this message translates to:
  /// **'La Pyramide'**
  String get home_title;

  /// No description provided for @home_subtitle.
  ///
  /// In fr, this message translates to:
  /// **'Le jeu de cartes du chaos'**
  String get home_subtitle;

  /// No description provided for @home_play_local.
  ///
  /// In fr, this message translates to:
  /// **'🃏 Jouer en local'**
  String get home_play_local;

  /// No description provided for @home_play_online.
  ///
  /// In fr, this message translates to:
  /// **'🌐 Jouer en ligne'**
  String get home_play_online;

  /// No description provided for @home_rules.
  ///
  /// In fr, this message translates to:
  /// **'📖 Règles du jeu'**
  String get home_rules;

  /// No description provided for @home_settings.
  ///
  /// In fr, this message translates to:
  /// **'⚙️ Paramètres'**
  String get home_settings;

  /// No description provided for @auth_title.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get auth_title;

  /// No description provided for @auth_google.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get auth_google;

  /// No description provided for @auth_apple.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Apple'**
  String get auth_apple;

  /// No description provided for @auth_anonymous.
  ///
  /// In fr, this message translates to:
  /// **'Jouer sans compte'**
  String get auth_anonymous;

  /// No description provided for @lobby_players_title.
  ///
  /// In fr, this message translates to:
  /// **'Les joueurs'**
  String get lobby_players_title;

  /// No description provided for @lobby_add_player.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un joueur'**
  String get lobby_add_player;

  /// No description provided for @lobby_player_name.
  ///
  /// In fr, this message translates to:
  /// **'Nom du joueur'**
  String get lobby_player_name;

  /// No description provided for @lobby_start_game.
  ///
  /// In fr, this message translates to:
  /// **'Lancer la partie !'**
  String get lobby_start_game;

  /// No description provided for @lobby_min_players.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 2 joueurs requis'**
  String get lobby_min_players;

  /// No description provided for @lobby_pyramid_size.
  ///
  /// In fr, this message translates to:
  /// **'Taille de la pyramide'**
  String get lobby_pyramid_size;

  /// No description provided for @lobby_variants.
  ///
  /// In fr, this message translates to:
  /// **'Variantes'**
  String get lobby_variants;

  /// No description provided for @lobby_bluff_mode.
  ///
  /// In fr, this message translates to:
  /// **'Mode Bluff'**
  String get lobby_bluff_mode;

  /// No description provided for @lobby_double_bet.
  ///
  /// In fr, this message translates to:
  /// **'Double Mise'**
  String get lobby_double_bet;

  /// No description provided for @lobby_super_challenge.
  ///
  /// In fr, this message translates to:
  /// **'Super Challenge'**
  String get lobby_super_challenge;

  /// No description provided for @online_room_code.
  ///
  /// In fr, this message translates to:
  /// **'Code de salle'**
  String get online_room_code;

  /// No description provided for @online_create_room.
  ///
  /// In fr, this message translates to:
  /// **'Créer une salle'**
  String get online_create_room;

  /// No description provided for @online_join_room.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre'**
  String get online_join_room;

  /// No description provided for @online_enter_code.
  ///
  /// In fr, this message translates to:
  /// **'Entrer le code'**
  String get online_enter_code;

  /// No description provided for @online_waiting.
  ///
  /// In fr, this message translates to:
  /// **'En attente des joueurs...'**
  String get online_waiting;

  /// No description provided for @online_ready.
  ///
  /// In fr, this message translates to:
  /// **'Prêt !'**
  String get online_ready;

  /// No description provided for @online_start.
  ///
  /// In fr, this message translates to:
  /// **'Lancer la partie'**
  String get online_start;

  /// No description provided for @online_players_connected.
  ///
  /// In fr, this message translates to:
  /// **'{count} joueur(s) connecté(s)'**
  String online_players_connected(int count);

  /// No description provided for @game_reveal_card.
  ///
  /// In fr, this message translates to:
  /// **'Retourner la carte'**
  String get game_reveal_card;

  /// No description provided for @game_its_your_turn.
  ///
  /// In fr, this message translates to:
  /// **'C\'est ton tour !'**
  String get game_its_your_turn;

  /// No description provided for @game_pass_phone.
  ///
  /// In fr, this message translates to:
  /// **'Passe le téléphone à'**
  String get game_pass_phone;

  /// No description provided for @game_tap_to_continue.
  ///
  /// In fr, this message translates to:
  /// **'Appuie pour continuer'**
  String get game_tap_to_continue;

  /// No description provided for @game_drink_sips.
  ///
  /// In fr, this message translates to:
  /// **'{name} doit prendre {sips} pénalité(s) !'**
  String game_drink_sips(String name, int sips);

  /// No description provided for @game_bluff_question.
  ///
  /// In fr, this message translates to:
  /// **'{name} bluffe-t-il ?'**
  String game_bluff_question(String name);

  /// No description provided for @game_challenge.
  ///
  /// In fr, this message translates to:
  /// **'Je Challenge !'**
  String get game_challenge;

  /// No description provided for @game_accept.
  ///
  /// In fr, this message translates to:
  /// **'J\'accepte'**
  String get game_accept;

  /// No description provided for @game_bluff_caught.
  ///
  /// In fr, this message translates to:
  /// **'BLUFF DÉMASQUÉ ! 😈'**
  String get game_bluff_caught;

  /// No description provided for @game_bluff_success.
  ///
  /// In fr, this message translates to:
  /// **'PAS DE BLUFF ! ✅'**
  String get game_bluff_success;

  /// No description provided for @game_row_sips.
  ///
  /// In fr, this message translates to:
  /// **'Rangée {row} — {sips} pénalité(s)'**
  String game_row_sips(int row, int sips);

  /// No description provided for @scoreboard_title.
  ///
  /// In fr, this message translates to:
  /// **'Résultats'**
  String get scoreboard_title;

  /// No description provided for @scoreboard_winner.
  ///
  /// In fr, this message translates to:
  /// **'Vainqueur'**
  String get scoreboard_winner;

  /// No description provided for @scoreboard_most_drunk.
  ///
  /// In fr, this message translates to:
  /// **'Le plus assoiffé 🍺'**
  String get scoreboard_most_drunk;

  /// No description provided for @scoreboard_best_bluffer.
  ///
  /// In fr, this message translates to:
  /// **'Meilleur Bluffeur 😈'**
  String get scoreboard_best_bluffer;

  /// No description provided for @scoreboard_total_sips.
  ///
  /// In fr, this message translates to:
  /// **'{sips} pénalités au total'**
  String scoreboard_total_sips(int sips);

  /// No description provided for @scoreboard_play_again.
  ///
  /// In fr, this message translates to:
  /// **'Rejouer !'**
  String get scoreboard_play_again;

  /// No description provided for @scoreboard_home.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get scoreboard_home;

  /// No description provided for @rules_title.
  ///
  /// In fr, this message translates to:
  /// **'Règles du jeu'**
  String get rules_title;

  /// No description provided for @settings_title.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings_title;

  /// No description provided for @settings_sound.
  ///
  /// In fr, this message translates to:
  /// **'Sons'**
  String get settings_sound;

  /// No description provided for @settings_vibration.
  ///
  /// In fr, this message translates to:
  /// **'Vibrations'**
  String get settings_vibration;

  /// No description provided for @settings_language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settings_language;

  /// No description provided for @settings_color_blind.
  ///
  /// In fr, this message translates to:
  /// **'Mode daltonien'**
  String get settings_color_blind;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
