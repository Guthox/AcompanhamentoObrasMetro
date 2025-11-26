// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:obras_view/util/components/obra_detalhe/visao_geral/obra_info_item.dart';
import 'package:obras_view/util/components/obra_detalhe/visao_geral/status_card.dart';
import 'package:obras_view/util/cores.dart';
import 'package:obras_view/util/info.dart';
import 'package:obras_view/util/obras.dart';
import 'package:http/http.dart' as http;

class VisaoGeral extends StatefulWidget {
  final Obras obra;

  const VisaoGeral({required this.obra, super.key});

  @override
  State<VisaoGeral> createState() => _VisaoGeralState();
}

class _VisaoGeralState extends State<VisaoGeral> {
  // Variáveis para guardar o estado atualizado da tela
  late double progressoAtual;
  late String descricaoAtual;
  late String statusAtual;
  bool carregando = false;

  @override
  void initState() {
    super.initState();
    // 1. Carrega os dados iniciais que vieram da tela anterior
    _inicializarDadosLocais();
    // 2. Busca imediatamente os dados frescos do banco de dados
    _atualizarDadosDoBanco();
  }

  // Isso garante que se a tela pai mandar atualizar, essa tela obedece
  @override
  void didUpdateWidget(covariant VisaoGeral oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.obra != oldWidget.obra) {
       _inicializarDadosLocais();
    }
    // Sempre que o widget for reconstruído pelo pai, busca dados novos
    _atualizarDadosDoBanco();
  }

  void _inicializarDadosLocais() {
    progressoAtual = widget.obra.progresso;
    descricaoAtual = widget.obra.descricao;
    statusAtual = widget.obra.status;
  }

  // --- FUNÇÃO QUE VAI NO BANCO PEGAR O VALOR REAL (13%) ---
  Future<void> _atualizarDadosDoBanco() async {
    if (carregando) return;
    
    // Pequeno delay para garantir que transições de tela terminem
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) return;
    
    // Marca que está atualizando (sem travar a tela com loading)
    carregando = true;

    try {
      final uri = Uri.parse("http://127.0.0.1:8000/obra/${widget.obra.id}");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);
        
        if (mounted) {
          setState(() {
            // AQUI É A MÁGICA: Pega o valor do banco e joga na tela
            progressoAtual = (dados['progresso'] ?? 0.0).toDouble();
            descricaoAtual = dados['descricao'] ?? descricaoAtual;
            statusAtual = dados['status'] ?? statusAtual;
            
            // Atualiza também o objeto original para manter sincronia
            widget.obra.progresso = progressoAtual;
            widget.obra.descricao = descricaoAtual;
            widget.obra.status = statusAtual;
          });
        }
      }
    } catch (e) {
      print("Erro ao atualizar dados da obra: $e");
    } finally {
      if (mounted) carregando = false;
    }
  }

  // --- CÁLCULO DE STATUS (Mantido igual) ---
  Map<String, dynamic> _calcularStatusObra(double progressoReal) {
    if (widget.obra.dataFim == null) {
      return {"texto": "Sem data final", "cor": Colors.grey, "esperado": 0.0};
    }

    final now = DateTime.now();
    final hoje = DateTime(now.year, now.month, now.day);
    final inicio = DateTime(widget.obra.dataInicio.year, widget.obra.dataInicio.month, widget.obra.dataInicio.day);
    final fim = DateTime(widget.obra.dataFim!.year, widget.obra.dataFim!.month, widget.obra.dataFim!.day);

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
    int diasRestantes = 0;
    if (widget.obra.dataFim != null) {
      final now = DateTime.now();
      final hoje = DateTime(now.year, now.month, now.day);
      final fim = DateTime(widget.obra.dataFim!.year, widget.obra.dataFim!.month, widget.obra.dataFim!.day);
      diasRestantes = fim.difference(hoje).inDays;
    }

    // Usa a variável de estado 'progressoAtual' em vez de calcular manualmente
    final statusData = _calcularStatusObra(progressoAtual);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      // Adicionei RefreshIndicator para você poder puxar a tela pra baixo e atualizar manualmente também
      body: RefreshIndicator(
        onRefresh: () async {
            carregando = false; 
            await _atualizarDadosDoBanco();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // === IMAGEM HERO ===
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                    child: Image.asset(
                      widget.obra.imagem,
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
                      widget.obra.nome,
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
                  children: [
                    // === STATUS E BARRA DE PROGRESSO ===
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(progressoAtual * 100).toStringAsFixed(0)}%', // Usa o valor do estado
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
                                value: progressoAtual, // Usa o valor do estado
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
                    if (widget.obra.dataFim != null)
                      Row(
                        children: [
                          Expanded(
                            child: StatusCard(
                              icon: Icons.timer, 
                              label: "Prazo", 
                              value: diasRestantes < 0 
                                  ? "${diasRestantes.abs()} dias atraso" 
                                  : "$diasRestantes dias restantes", 
                              valueColor: (diasRestantes < 0 || (diasRestantes < 10 && progressoAtual < 0.9)) 
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
                      child: Text(descricaoAtual, style: const TextStyle(fontSize: 15, height: 1.4)), // Usa variável local
                    ),

                    const SizedBox(height: 24),

                    // === INFORMAÇÕES TÉCNICAS ===
                    Text("Detalhes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Cores.azulMetro)),
                    const SizedBox(height: 12),
                    
                    InfoItem(icon: Icons.location_on, titulo: "Localização", valor: widget.obra.localizacao),
                    InfoItem(icon: Icons.engineering, titulo: "Responsável", valor: widget.obra.responsavel),
                    InfoItem(icon: Icons.calendar_today, titulo: "Início", valor: _formatarData(widget.obra.dataInicio)),
                    if (widget.obra.dataFim != null)
                      InfoItem(icon: Icons.flag, titulo: "Previsão de Término", valor: _formatarData(widget.obra.dataFim!)),

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
                              content: Text("Tem certeza que deseja excluir '${widget.obra.nome}'? Isso apagará todas as câmeras e fotos associadas."),
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
                            try {
                              await http.delete(Uri.parse("http://127.0.0.1:8000/obras/${widget.obra.id}"));
                            } catch (e) {
                              print("Erro ao deletar do backend: $e");
                            }

                            final idsCamerasParaExcluir = Info.listaCameras
                                .where((c) => c.obraId == widget.obra.id)
                                .map((c) => c.id)
                                .toList();
                            Info.listaImagens.removeWhere((img) => idsCamerasParaExcluir.contains(img.cameraId));
                            Info.listaCameras.removeWhere((c) => c.obraId == widget.obra.id);
                            Info.listaObras.removeWhere((o) => o.id == widget.obra.id);

                            if (mounted) Navigator.pop(context, 'deleted');
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
      ),
    );
  }
}