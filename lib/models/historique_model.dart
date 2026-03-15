class HistoriqueModel {
  final int idSeance;
  final DateTime dateSeance;
  final String heureDebut;
  final String heureFin;
  final String nomSurveillant;
  final String prenomSurveillant;
  final String ecue;
  final String classe;
  final int totalPresents;
  final int totalAbsents;

  HistoriqueModel({
    required this.idSeance,
    required this.dateSeance,
    required this.heureDebut,
    required this.heureFin,
    required this.nomSurveillant,
    required this.prenomSurveillant,
    required this.ecue,
    required this.classe,
    required this.totalPresents,
    required this.totalAbsents,
  });

  factory HistoriqueModel.fromMap(Map<String, dynamic> map) {
    return HistoriqueModel(
      idSeance: map['id_seance'],
      dateSeance: DateTime.parse(map['date_seance']),
      heureDebut: map['heure_debut'],
      heureFin: map['heure_fin'],
      nomSurveillant: map['nom_surveillant'],
      prenomSurveillant: map['prenom_surveillant'],
      ecue: map['intitule_ecue'],
      classe: map['classe'],
      totalPresents: map['total_presents'] ?? 0,
      totalAbsents: map['total_absents'] ?? 0,
    );
  }
}
