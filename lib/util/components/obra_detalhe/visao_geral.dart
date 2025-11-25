// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:obras_view/util/components/obra_detalhe/visao_geral/obra_info_item.dart';
import 'package:obras_view/util/components/obra_detalhe/visao_geral/status_card.dart';
import 'package:obras_view/util/cores.dart';
import 'package:obras_view/util/info.dart';
import 'package:obras_view/util/obras.dart';
import 'package:http/http.dart' as http;

class VisaoGeral extends StatelessWidget {
  final Obras obra;

  const VisaoGeral({required this.obra, super.key});

  // --- 1. CÁLCULO DE PROGRESSO (IDÊNTICO AO BACKEND/CAMERA) ---
  double _calcularProgressoReal() {
    final camerasDaObra = Info.listaCameras.where((c) => c.obraId == obra.id).toList();

    if (camerasDaObra.isEmpty) return 0.0;

    double somaPorcentagens = 0.0;
    int camerasValidas = 0;

    for (var camera in camerasDaObra) {
      if (camera.estatisticas == null || camera.estatisticas!.isEmpty) continue;
      
      camerasValidas++;
      
      if (camera.estatisticasReal == null) {
        somaPorcentagens += 0.0;
        continue;
      }

      int totalEsperado = 0;
      int totalReal = 0;

      camera.estatisticas!.forEach((key, value) {
        int esperadoItem = value as int;
        totalEsperado += esperadoItem;

        if (camera.estatisticasReal!.containsKey(key)) {
          int realItem = camera.estatisticasReal![key] as int;
          
          if (realItem > esperadoItem) {
            totalReal += esperadoItem;
          } else {
            totalReal += realItem;
          }
        }
      });

      if (totalEsperado > 0) {
        double progressoCam = totalReal / totalEsperado;
        
        if (progressoCam < 0.5) {
        } else if (progressoCam < 0.8) {
          progressoCam += 0.1;
        } else if (progressoCam < 0.95) {
          progressoCam += 0.05;
        }
        
        // Trava em 100%
        if (progressoCam > 1.0) progressoCam = 1.0;
        
        somaPorcentagens += progressoCam;
      }
    }

    if (camerasValidas == 0) return 0.0;
    return somaPorcentagens / camerasValidas;
  }

  // --- 2. CÁLCULO DE STATUS (REAL VS TEMPO) ---
  Map<String, dynamic> _calcularStatusObra(double progressoReal) {
    if (obra.dataFim == null) {
      return {"texto": "Sem data final", "cor": Colors.grey, "esperado": 0.0};
    }

    final now = DateTime.now();
    final hoje = DateTime(now.year, now.month, now.day);
    final inicio = DateTime(obra.dataInicio.year, obra.dataInicio.month, obra.dataInicio.day);
    final fim = DateTime(obra.dataFim!.year, obra.dataFim!.month, obra.dataFim!.day);

    if (progressoReal >= 1.0) {
      return {"texto": "Concluída", "cor": Colors.green, "esperado": 1.0};
    }

    if (hoje.isBefore(inicio)) {
      return {"texto": "Não iniciada", "cor": Colors.grey, "esperado": 0.0};
    }

    final prazoTotal = fim.difference(inicio).inDays;
    final diasPassados = hoje.difference(inicio).inDays;

    if (prazoTotal <= 0) return {"texto": "Prazo inválido", "cor": Colors.grey, "esperado": 0.0};

    double progressoEsperado = diasPassados / prazoTotal;
    if (progressoEsperado > 1.0) progressoEsperado = 1.0;
    if (progressoEsperado < 0.0) progressoEsperado = 0.0;

    if (hoje.isAfter(fim) && progressoReal < 1.0) {
       return {"texto": "Atrasada (Prazo Esgotado)", "cor": Colors.red, "esperado": 1.0};
    }

    String textoStatus;
    Color corStatus;

    if (progressoReal < progressoEsperado) {
      textoStatus = "Atrasada";
      corStatus = Colors.red;
    } else if (progressoReal > progressoEsperado) {
      textoStatus = "Adiantada";
      corStatus = Colors.green;
    } else {
      textoStatus = "Em dia";
      corStatus = Colors.blue;
    }

    return {
      "texto": textoStatus,
      "cor": corStatus,
      "esperado": progressoEsperado
    };
  }

  String _formatarData(DateTime data) {
    return "${data.day.toString().padLeft(2, '0')}/"
        "${data.month.toString().padLeft(2, '0')}/"
        "${data.year}";
  }

  @override
  Widget build(BuildContext context) {
    // 1. Calcula o progresso atualizado
    double progressoReal = _calcularProgressoReal();
    obra.progresso = progressoReal; 
    
    // 2. Calcula dias restantes
    int diasRestantes = 0;
    if (obra.dataFim != null) {
      final now = DateTime.now();
      final hoje = DateTime(now.year, now.month, now.day);
      final fim = DateTime(obra.dataFim!.year, obra.dataFim!.month, obra.dataFim!.day);
      diasRestantes = fim.difference(hoje).inDays;
    }

    // 3. Obtém dados de status e cor
    final statusData = _calcularStatusObra(progressoReal);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // === IMAGEM HERO ===
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  child: Image.asset(
                    obra.imagem,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 220,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 220,
                      color: Cores.azulMetro,
                      child: const Center(child: Icon(Icons.apartment, size: 60, color: Colors.white30)),
                    ),
                  ),
                ),
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.4), Colors.transparent],
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
                  
                  // === STATUS E BARRA DE PROGRESSO ===
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(
                          statusData['texto'],
                          style: TextStyle(
                            color: statusData['cor'] == Colors.grey ? Colors.black87 : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12
                          ),
                        ),
                        backgroundColor: statusData['cor'],
                        side: BorderSide.none,
                        padding: const EdgeInsets.all(0),
                      ),
                      Text(
                        '${(progressoReal * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Cores.azulMetro, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progressoReal,
                              color: statusData['cor'],
                              backgroundColor: Colors.grey[300],
                              minHeight: 12,
                            ),
                          ),
                          
                          if (statusData['esperado'] > 0 && statusData['esperado'] < 1.0)
                            Padding(
                              padding: EdgeInsets.only(left: constraints.maxWidth * statusData['esperado']),
                              child: Column(
                                children: [
                                  Container(width: 2, height: 6, color: Colors.grey[600]),
                                  Text(
                                    "Esperado",
                                    style: TextStyle(fontSize: 9, color: Colors.grey[700], fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // === CARDS INFORMATIVOS ===
                  if (obra.dataFim != null)
                    Row(
                      children: [
                        Expanded(
                          child: StatusCard(
                            icon: Icons.timer, 
                            label: "Prazo", 
                            value: diasRestantes < 0 
                                ? "${diasRestantes.abs()} dias atraso" 
                                : "$diasRestantes dias restantes", 
                            valueColor: (diasRestantes < 0 || (diasRestantes < 10 && progressoReal < 0.9)) 
                                ? Colors.red 
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatusCard(
                            icon: Icons.analytics, 
                            label: "Situação", 
                            value: statusData['texto'], 
                            valueColor: statusData['cor'],
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // === DESCRIÇÃO ===
                  Text("Descrição", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Cores.azulMetro)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200)
                    ),
                    child: Text(obra.descricao, style: const TextStyle(fontSize: 15, height: 1.4)),
                  ),

                  const SizedBox(height: 24),

                  // === INFORMAÇÕES TÉCNICAS ===
                  Text("Detalhes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Cores.azulMetro)),
                  const SizedBox(height: 12),
                  
                  InfoItem(icon: Icons.location_on, titulo: "Localização", valor: obra.localizacao),
                  InfoItem(icon: Icons.engineering, titulo: "Responsável", valor: obra.responsavel),
                  InfoItem(icon: Icons.calendar_today, titulo: "Início", valor: _formatarData(obra.dataInicio)),
                  if (obra.dataFim != null)
                    InfoItem(icon: Icons.flag, titulo: "Previsão de Término", valor: _formatarData(obra.dataFim!)),

                  const SizedBox(height: 40),

                  // === BOTÃO EXCLUIR ===
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      label: const Text("Excluir Obra", style: TextStyle(color: Colors.redAccent, fontSize: 16)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.redAccent)
                        ),
                      ),
                      onPressed: () async {
                        final confirmar = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Excluir obra"),
                            content: Text("Tem certeza que deseja excluir '${obra.nome}'? Isso apagará todas as câmeras e fotos associadas."),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Excluir Tudo", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirmar == true) {
                          // 1. Deletar do Banco (se aplicável)
                          try {
                            await http.delete(Uri.parse("http://127.0.0.1:8000/obras/${obra.id}"));
                          } catch (e) {
                            print("Erro ao deletar do backend: $e");
                          }

                          // 2. Limpeza em Cascata (Local)
                          final idsCamerasParaExcluir = Info.listaCameras
                              .where((c) => c.obraId == obra.id)
                              .map((c) => c.id)
                              .toList();
                          Info.listaImagens.removeWhere((img) => idsCamerasParaExcluir.contains(img.cameraId));
                          Info.listaCameras.removeWhere((c) => c.obraId == obra.id);
                          Info.listaObras.removeWhere((o) => o.id == obra.id);

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
}