import 'dart:typed_data';

class HistoriqueModel {
  final int idSeance;
  final DateTime dateSeance;
  final String heureDebut;
  final String heureFin;
  final String nomSurveillant;
  final String prenomSurveillant;
  final String nomProf;
  final String prenomProf;
  final String nomSalle;
  final Uint8List? signatureProf;
  final String ecue;
  final String classe;
  final int effectif;
  final int totalPresents;
  final int totalAbsents;

  HistoriqueModel({
    required this.idSeance,
    required this.dateSeance,
    required this.heureDebut,
    required this.heureFin,
    required this.nomSurveillant,
    required this.prenomSurveillant,
    required this.nomProf,
    required this.prenomProf,
    required this.nomSalle,
    this.signatureProf,
    required this.ecue,
    required this.classe,
    required this.effectif,
    required this.totalPresents,
    required this.totalAbsents,
  });

  factory HistoriqueModel.fromMap(Map<String, dynamic> map) {
    Uint8List? sig;
    if (map['signature_prof'] != null) {
      if (map['signature_prof'] is List) {
        sig = Uint8List.fromList(List<int>.from(map['signature_prof']));
      }
    }

    return HistoriqueModel(
      idSeance: map['id_seance'],
      dateSeance: DateTime.parse(map['date_seance']),
      heureDebut: map['heure_debut'],
      heureFin: map['heure_fin'],
      nomSurveillant: map['nom_surveillant'] ?? '',
      prenomSurveillant: map['prenom_surveillant'] ?? '',
      nomProf: map['nom_prof'] ?? '',
      prenomProf: map['prenom_prof'] ?? '',
      nomSalle: map['nom_salle'] ?? '',
      signatureProf: sig,
      ecue: map['intitule_ecue'] ?? '',
      classe: map['classe'] ?? '',
      effectif: map['effectif'] ?? 0,
      totalPresents: map['total_presents'] ?? 0,
      totalAbsents: map['total_absents'] ?? 0,
    );
  }
}


