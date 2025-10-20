import 'package:flutter/material.dart';
import '../util/cores.dart';
import '../util/obras.dart';

class ObraDetalhe extends StatelessWidget {
  final Obras obra;

  const ObraDetalhe({required this.obra, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(obra.nome),
        titleTextStyle: TextStyle(color: Colors.white),
        backgroundColor: Cores.azulMetro,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // === IMAGEM PRINCIPAL ===
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                  child: Image.asset(
                    obra.imagem,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 220,
                  ),
                ),
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Text(
                    obra.nome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 8,
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // === CONTEÚDO ===
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === STATUS E PROGRESSO ===
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(
                          obra.status,
                          style: TextStyle(
                            color: obra.status == 'Concluída'
                                ? Colors.green[800]
                                : Cores.azulMetro,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Colors.grey[200],
                      ),
                      Text(
                        '${(obra.progresso * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Cores.azulMetro,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: obra.progresso,
                    color: Cores.azulMetro,
                    backgroundColor: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                    minHeight: 10,
                  ),

                  const SizedBox(height: 24),

                  // === DESCRIÇÃO ===
                  Text(
                    "Descrição",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Cores.azulMetro,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    obra.descricao,
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),

                  const SizedBox(height: 24),

                  // === INFORMAÇÕES ===
                  Text(
                    "Informações",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Cores.azulMetro,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _infoItem(Icons.location_on, "Localização", obra.localizacao),
                  _infoItem(Icons.engineering, "Responsável", obra.responsavel),
                  _infoItem(Icons.calendar_today, "Início",
                      _formatarData(obra.dataInicio)),
                  if (obra.dataFim != null)
                    _infoItem(Icons.flag, "Término",
                        _formatarData(obra.dataFim!)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String titulo, String valor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Cores.azulMetro, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  valor,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatarData(DateTime data) {
    return "${data.day.toString().padLeft(2, '0')}/"
        "${data.month.toString().padLeft(2, '0')}/"
        "${data.year}";
  }
}
