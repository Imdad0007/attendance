import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/historique_model.dart';
import '../composants/colors.dart';

class DetailHistorique extends StatelessWidget {
  final HistoriqueModel item;

  const DetailHistorique({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Détails de la séance"),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _info("Surveillant", item.nomSurveillant),
            _info("Date", DateFormat('dd/MM/yyyy').format(item.dateSeance)),
            _info("Heure début", item.heureDebut),
            _info("Heure fin", item.heureFin),
            _info("ECUE", item.ecue),
            _info("Classe", item.classe),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
