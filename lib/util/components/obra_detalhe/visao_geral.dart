// ignore_for_file: deprecated_member_use, use_build_context_synchronously

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
  late double progressoAtual;
  late String descricaoAtual;
  late String statusAtual;
  bool carregando = false;

  @override
  void initState() {
    super.initState();
    _inicializarDadosLocais();
    _atualizarDadosDoBanco();
  }

  @override
  void didUpdateWidget(covariant VisaoGeral oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.obra != oldWidget.obra) {
       _inicializarDadosLocais();
    }
    _atualizarDadosDoBanco();
  }

  void _inicializarDadosLocais() {
    progressoAtual = widget.obra.progresso;
    descricaoAtual = widget.obra.descricao;
    statusAtual = widget.obra.status;
  }

  // --- BUSCA DADOS E APLICA LÓGICA AUTOMÁTICA ---
  Future<void> _atualizarDadosDoBanco() async {
    if (carregando) return;
    if (!mounted) return;
    
    try {
      final uri = Uri.parse("http://127.0.0.1:8000/obra/${widget.obra.id}");
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);
        
        if (mounted) {
          setState(() {
            progressoAtual = (dados['progresso'] ?? 0.0).toDouble();
            descricaoAtual = dados['descricao'] ?? descricaoAtual;
            statusAtual = dados['status'] ?? statusAtual; 
            
            widget.obra.progresso = progressoAtual;
            widget.obra.descricao = descricaoAtual;
            widget.obra.status = statusAtual;
          });

          _verificarAtualizacaoAutomaticaDeStatus();
        }
      }
    } catch (e) {
      print("Erro ao atualizar dados: $e");
    }
  }

  // --- LÓGICA INTELIGENTE DE STATUS ---
  void _verificarAtualizacaoAutomaticaDeStatus() {
    if (statusAtual == "Parada") return;

    final statusCalculado = _calcularStatusMatematico(progressoAtual);
    final textoCalculado = statusCalculado['texto'];

    if (textoCalculado != statusAtual) {
      _salvarStatusNoBanco(textoCalculado);
    }
  }

  Future<void> _salvarStatusNoBanco(String novoStatus) async {
    try {
      final uri = Uri.parse("http://127.0.0.1:8000/obras/${widget.obra.id}/status");
      final response = await http.patch(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": novoStatus}),
      );

      if (response.statusCode == 200) {
        setState(() {
          statusAtual = novoStatus;
          widget.obra.status = novoStatus;
        });
      }
    } catch (e) {
      print("Erro ao salvar status: $e");
    }
  }

  // --- CÁLCULO MATEMÁTICO PURO ---
  Map<String, dynamic> _calcularStatusMatematico(double progressoReal) {
    
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
       return {"texto": "Atrasada", "cor": Colors.red, "esperado": 1.0};
    }

    String textoStatus;
    Color corStatus;

    if (progressoReal < (progressoEsperado)) {
      textoStatus = "Atrasada";
      corStatus = Colors.red;
    } else if (progressoReal > (progressoEsperado)) {
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

    Map<String, dynamic> statusData;
    
    if (statusAtual == "Parada") {
      statusData = {"texto": "Parada", "cor": Colors.orange, "esperado": 0.0};
    } else {
      statusData = _calcularStatusMatematico(progressoAtual);
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
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

              // === CONTEÚDO PRINCIPAL ===
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // 1. BARRA DE PROGRESSO (MUDOU PARA CIMA)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progresso',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[700]),
                        ),
                        Text(
                          '${(progressoAtual * 100).toStringAsFixed(0)}%',
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
                                value: progressoAtual,
                                color: statusData['cor'],
                                backgroundColor: Colors.grey[300],
                                minHeight: 12,
                              ),
                            ),
                            
                            if (statusAtual != "Parada" && statusData['esperado'] > 0 && statusData['esperado'] < 1.0)
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

                    // 2. CARDS INFORMATIVOS (PRAZO E SITUAÇÃO)
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
                              valueColor: (diasRestantes < 0) 
                                  ? Colors.red 
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatusCard(
                              icon: Icons.analytics, 
                              label: "Situação", 
                              value: statusAtual,
                              valueColor: statusData['cor'],
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 12),

                    // 3. DROPDOWN DE CONTROLE DE STATUS (MOVIDO E ESTILIZADO)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        // Sombra igual aos Cards
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      child: Row(
                        children: [
                          // Ícone igual ao InfoItem
                          Icon(Icons.toggle_on_outlined, color: Colors.grey, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: statusAtual == "Parada" ? "Parada" : "Automático",
                                icon: Icon(Icons.keyboard_arrow_down, color: Cores.azulMetro),
                                style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
                                items: const [
                                  DropdownMenuItem(value: "Automático", child: Text("Status Automático")),
                                  DropdownMenuItem(value: "Parada", child: Text("Status: Parada")),
                                ],
                                onChanged: (novoModo) async {
                                  if (novoModo == "Parada") {
                                    await _salvarStatusNoBanco("Parada");
                                  } else {
                                    final calculado = _calcularStatusMatematico(progressoAtual);
                                    await _salvarStatusNoBanco(calculado['texto']);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 4. RESTANTE (Descrição, Detalhes...)
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
                      child: Text(descricaoAtual, style: const TextStyle(fontSize: 15, height: 1.4)),
                    ),

                    const SizedBox(height: 24),
                    Text("Detalhes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Cores.azulMetro)),
                    const SizedBox(height: 12),
                    InfoItem(icon: Icons.location_on, titulo: "Localização", valor: widget.obra.localizacao),
                    InfoItem(icon: Icons.engineering, titulo: "Responsável", valor: widget.obra.responsavel),
                    InfoItem(icon: Icons.calendar_today, titulo: "Início", valor: _formatarData(widget.obra.dataInicio)),
                    if (widget.obra.dataFim != null)
                      InfoItem(icon: Icons.flag, titulo: "Previsão de Término", valor: _formatarData(widget.obra.dataFim!)),

                    const SizedBox(height: 40),
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
                              content: Text("Tem certeza que deseja excluir '${widget.obra.nome}'?"),
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
                              print("Erro ao deletar: $e");
                            }
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