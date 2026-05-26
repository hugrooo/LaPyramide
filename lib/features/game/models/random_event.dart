class RandomEvent {
  final String title;
  final String description;
  final String emoji;
  final String type; // 'global', 'target', 'mini_game'

  const RandomEvent({
    required this.title,
    required this.description,
    required this.emoji,
    required this.type,
  });
}
