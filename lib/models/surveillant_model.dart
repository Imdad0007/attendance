class Surveillant {
  final int? idSurveillant;
  final String? authId; // UUID from Supabase Auth
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final String role;

  Surveillant({
    this.idSurveillant,
    this.authId,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    required this.role,
  });

  // Pour l'affichage facile
  String get nomComplet => "$nom $prenom";

  factory Surveillant.fromMap(Map<String, dynamic> map) {
    return Surveillant(
      idSurveillant: map['id_surveillant'],
      authId: map['auth_id'],
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      email: map['email'] ?? '',
      telephone: map['telephone'],
      role: map['role'] ?? 'surveillant',
    );
  }

  Surveillant copyWith({
    int? idSurveillant,
    String? authId,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? role,
  }) {
    return Surveillant(
      idSurveillant: idSurveillant ?? this.idSurveillant,
      authId: authId ?? this.authId,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      role: role ?? this.role,
    );
  }
}
