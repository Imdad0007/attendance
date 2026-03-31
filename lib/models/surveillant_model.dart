class Surveillant {
  final int? idSurveillant;
  final String nom;
  final String prenom;
  final String username;
  final String? telephone;
  final String role;
  final String? mdp;

  Surveillant({
    this.idSurveillant,
    required this.nom,
    required this.prenom,
    required this.username,
    this.telephone,
    required this.role,
    this.mdp,
  });

  // Pour l'affichage facile
  String get nomComplet => "$nom $prenom";

  factory Surveillant.fromMap(Map<String, dynamic> map) {
    return Surveillant(
      idSurveillant: map['id_surveillant'], // CORRIGÉ ici aussi
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      username: map['username'] ?? '',
      telephone: map['telephone'],
      role: map['role'] ?? 'adjoint',
      mdp: map['mdp'],
    );
  }

  Surveillant copyWith({
    int? idSurveillant,
    String? nom,
    String? prenom,
    String? username,
    String? telephone,
    String? role,
    String? mdp,
  }) {
    return Surveillant(
      idSurveillant: idSurveillant ?? this.idSurveillant,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      username: username ?? this.username,
      telephone: telephone ?? this.telephone,
      role: role ?? this.role,
      mdp: mdp ?? this.mdp,
    );
  }
}
