import 'package:flutter/material.dart';
import 'package:obras_view/telas/enviar_imagem.dart';
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
        titleTextStyle: const TextStyle(color: Colors.white),
        backgroundColor: Cores.azulMetro,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
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
                      shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
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
                  _infoItem(
                    Icons.calendar_today,
                    "Início",
                    _formatarData(obra.dataInicio),
                  ),
                  if (obra.dataFim != null)
                    _infoItem(
                      Icons.flag,
                      "Término",
                      _formatarData(obra.dataFim!),
                    ),

                  const SizedBox(height: 40),

                  // === BOTÕES DE FOTOS ===
                  const SizedBox(height: 20),

                  Center(
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.add_a_photo,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Adicionar Fotos",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Cores.azulMetro,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EnviarImagem(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        ElevatedButton.icon(
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Ver Fotos",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EnviarImagem(), // MUDAR PARA O HISTORICO DE FOTOS QUANDO TIVER
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // === BOTÃO DE EXCLUIR ===
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Excluir obra",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final confirmar = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Excluir obra"),
                            content: Text(
                              "Tem certeza que deseja excluir '${obra.nome}'?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancelar"),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Excluir"),
                              ),
                            ],
                          ),
                        );

                        if (confirmar == true) {
                          Navigator.pop(context, 'deleted');
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
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
          ),
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
