// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'La Pyramide';

  @override
  String get home_title => 'La Pyramide';

  @override
  String get home_subtitle => 'Le jeu de cartes du chaos';

  @override
  String get home_play_local => '🃏 Jouer en local';

  @override
  String get home_play_online => '🌐 Jouer en ligne';

  @override
  String get home_rules => '📖 Règles du jeu';

  @override
  String get home_settings => '⚙️ Paramètres';

  @override
  String get auth_title => 'Se connecter';

  @override
  String get auth_google => 'Continuer avec Google';

  @override
  String get auth_apple => 'Continuer avec Apple';

  @override
  String get auth_anonymous => 'Jouer sans compte';

  @override
  String get lobby_players_title => 'Les joueurs';

  @override
  String get lobby_add_player => 'Ajouter un joueur';

  @override
  String get lobby_player_name => 'Nom du joueur';

  @override
  String get lobby_start_game => 'Lancer la partie !';

  @override
  String get lobby_min_players => 'Minimum 2 joueurs requis';

  @override
  String get lobby_pyramid_size => 'Taille de la pyramide';

  @override
  String get lobby_variants => 'Variantes';

  @override
  String get lobby_bluff_mode => 'Mode Bluff';

  @override
  String get lobby_double_bet => 'Double Mise';

  @override
  String get lobby_super_challenge => 'Super Challenge';

  @override
  String get online_room_code => 'Code de salle';

  @override
  String get online_create_room => 'Créer une salle';

  @override
  String get online_join_room => 'Rejoindre';

  @override
  String get online_enter_code => 'Entrer le code';

  @override
  String get online_waiting => 'En attente des joueurs...';

  @override
  String get online_ready => 'Prêt !';

  @override
  String get online_start => 'Lancer la partie';

  @override
  String online_players_connected(int count) {
    return '$count joueur(s) connecté(s)';
  }

  @override
  String get game_reveal_card => 'Retourner la carte';

  @override
  String get game_its_your_turn => 'C\'est ton tour !';

  @override
  String get game_pass_phone => 'Passe le téléphone à';

  @override
  String get game_tap_to_continue => 'Appuie pour continuer';

  @override
  String game_drink_sips(String name, int sips) {
    return '$name reçoit $sips pénalité(s) !';
  }

  @override
  String game_bluff_question(String name) {
    return '$name bluffe-t-il ?';
  }

  @override
  String get game_challenge => 'Je Challenge !';

  @override
  String get game_accept => 'J\'accepte';

  @override
  String get game_bluff_caught => 'BLUFF DÉMASQUÉ ! 😈';

  @override
  String get game_bluff_success => 'PAS DE BLUFF ! ✅';

  @override
  String game_row_sips(int row, int sips) {
    return 'Rangée $row — $sips pénalité(s)';
  }

  @override
  String get scoreboard_title => 'Résultats';

  @override
  String get scoreboard_winner => 'Vainqueur';

  @override
  String get scoreboard_most_drunk => 'Le plus puni 🎯';

  @override
  String get scoreboard_best_bluffer => 'Meilleur Bluffeur 😈';

  @override
  String scoreboard_total_sips(int sips) {
    return '$sips pénalités au total';
  }

  @override
  String get scoreboard_play_again => 'Rejouer !';

  @override
  String get scoreboard_home => 'Accueil';

  @override
  String get rules_title => 'Règles du jeu';

  @override
  String get settings_title => 'Paramètres';

  @override
  String get settings_sound => 'Sons';

  @override
  String get settings_vibration => 'Vibrations';

  @override
  String get settings_language => 'Langue';

  @override
  String get settings_color_blind => 'Mode daltonien';
}
