// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'The Pyramid';



  @override
  String get home_title => 'The Pyramid';

  @override
  String get home_subtitle => 'The card game of chaos';

  @override
  String get home_play_local => '🃏 Play Locally';

  @override
  String get home_play_online => '🌐 Play Online';

  @override
  String get home_rules => '📖 Rules';

  @override
  String get home_settings => '⚙️ Settings';

  @override
  String get auth_title => 'Sign In';

  @override
  String get auth_google => 'Continue with Google';

  @override
  String get auth_apple => 'Continue with Apple';

  @override
  String get auth_anonymous => 'Play without account';

  @override
  String get lobby_players_title => 'Players';

  @override
  String get lobby_add_player => 'Add a player';

  @override
  String get lobby_player_name => 'Player name';

  @override
  String get lobby_start_game => 'Start the game!';

  @override
  String get lobby_min_players => 'At least 2 players required';

  @override
  String get lobby_pyramid_size => 'Pyramid size';

  @override
  String get lobby_variants => 'Variants';

  @override
  String get lobby_bluff_mode => 'Bluff Mode';

  @override
  String get lobby_double_bet => 'Double Bet';

  @override
  String get lobby_super_challenge => 'Super Challenge';

  @override
  String get online_room_code => 'Room Code';

  @override
  String get online_create_room => 'Create Room';

  @override
  String get online_join_room => 'Join';

  @override
  String get online_enter_code => 'Enter the code';

  @override
  String get online_waiting => 'Waiting for players...';

  @override
  String get online_ready => 'Ready!';

  @override
  String get online_start => 'Start Game';

  @override
  String online_players_connected(int count) {
    return '$count player(s) connected';
  }

  @override
  String get game_reveal_card => 'Reveal card';

  @override
  String get game_its_your_turn => 'It\'s your turn!';

  @override
  String get game_pass_phone => 'Pass the phone to';

  @override
  String get game_tap_to_continue => 'Tap to continue';

  @override
  String game_drink_sips(String name, int sips) {
    return '$name receives $sips penalty(ies)!';
  }

  @override
  String game_bluff_question(String name) {
    return 'Is $name bluffing?';
  }

  @override
  String get game_challenge => 'I Challenge!';

  @override
  String get game_accept => 'I Accept';

  @override
  String get game_bluff_caught => 'BLUFF CAUGHT! 😈';

  @override
  String get game_bluff_success => 'NO BLUFF! ✅';

  @override
  String game_row_sips(int row, int sips) {
    return 'Row $row — $sips penalty(ies)';
  }

  @override
  String get scoreboard_title => 'Results';

  @override
  String get scoreboard_winner => 'Winner';

  @override
  String get scoreboard_most_drunk => 'Most Penalized 🎯';

  @override
  String get scoreboard_best_bluffer => 'Best Bluffer 😈';

  @override
  String scoreboard_total_sips(int sips) {
    return '$sips total penalties';
  }

  @override
  String get scoreboard_play_again => 'Play Again!';

  @override
  String get scoreboard_home => 'Home';

  @override
  String get rules_title => 'Game Rules';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_sound => 'Sounds';

  @override
  String get settings_vibration => 'Vibrations';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_color_blind => 'Color blind mode';
}
