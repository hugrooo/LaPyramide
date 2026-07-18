/// Liste de gages/challenges pour le mode sans alcool
class ChallengesData {
  static const List<String> physicalChallenges = [
    'Fais 5 pompes !',
    'Fais 10 squats !',
    'Tiens la position de la chaise pendant 15 secondes !',
    'Fais 5 burpees !',
    'Fais la planche pendant 20 secondes !',
    'Fais 10 jumping jacks !',
    'Tiens sur un pied pendant 15 secondes les yeux fermés !',
    'Fais 3 tours sur toi-même puis marche en ligne droite !',
  ];

  static const List<String> funChallenges = [
    'Imite un animal choisi par les autres joueurs pendant 10 secondes !',
    'Chante le refrain de la dernière chanson que tu as écoutée !',
    'Fais un compliment sincère à chaque joueur !',
    'Raconte une blague — si personne ne rit, recommence !',
    'Parle avec un accent étranger jusqu\'au prochain tour !',
    'Fais une grimace et garde-la pendant 10 secondes !',
    'Danse pendant 15 secondes sans musique !',
    'Dis un virelangue 3 fois de suite sans te tromper !',
    'Mime un film et les autres doivent deviner !',
    'Appelle un ami et dis-lui que tu l\'aimes sans explication !',
  ];

  static const List<String> dareChallenges = [
    'Laisse un autre joueur poster un story sur ton Instagram !',
    'Envoie un message "Tu me manques" au 3ème contact de ton répertoire !',
    'Montre la dernière photo de ta galerie !',
    'Lis à voix haute ton dernier message envoyé !',
    'Laisse les autres choisir ta photo de profil pour 24h !',
    'Fais un selfie ridicule et envoie-le à un ami !',
  ];

  /// Retourne un challenge aléatoire adapté au nombre de pénalités
  static String getChallenge(int penaltyCount) {
    if (penaltyCount <= 1) {
      return funChallenges[penaltyCount % funChallenges.length];
    } else if (penaltyCount <= 3) {
      return physicalChallenges[penaltyCount % physicalChallenges.length];
    } else {
      return dareChallenges[penaltyCount % dareChallenges.length];
    }
  }
}
