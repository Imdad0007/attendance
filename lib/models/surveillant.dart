class Surveillant {
  final int idSurveillant;
  final String nom;
  final String prenom;
  final String? telephone;
  final String username;

  Surveillant({
    required this.idSurveillant,
    required this.nom,
    required this.prenom,
    this.telephone,
    required this.username,
  });

  String get nomComplet => '$prenom $nom';

  factory Surveillant.fromMap(Map<String, dynamic> map) {
    return Surveillant(
      idSurveillant: map['id_surveillant'] as int? ?? 0,
      nom: map['nom'] as String? ?? '',
      prenom: map['prenom'] as String? ?? '', 
      telephone: map['telephone'] as String?,
      username: map['username'] as String? ?? '',
    );
  }
}
