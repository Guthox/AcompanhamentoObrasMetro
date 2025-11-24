import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:obras_view/telas/enviar_imagem.dart';
import '../util/cores.dart';
import '../util/obras.dart';

class ObraDetalhe extends StatefulWidget {
  final Obras obra;

  const ObraDetalhe({required this.obra, super.key});

  @override
  State<ObraDetalhe> createState() => _ObraDetalheState();
}

class _ObraDetalheState extends State<ObraDetalhe> {
  Obras? obraAtualizada;
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarObra();
  }

  Future<void> _carregarObra() async {
    final url = Uri.parse("http://127.0.0.1:8000/obra/${widget.obra.id}");

    final resp = await http.get(url);

    if (resp.statusCode == 200) {
      final dados = jsonDecode(resp.body);

      setState(() {
        obraAtualizada = Obras(
          id: dados["id"],
          nome: dados["nome"],
          descricao: dados["descricao"],
          localizacao: dados["localizacao"],
          responsavel: dados["responsavel"],
          status: dados["status"],
          dataInicio: DateTime.parse(dados["data_inicio"]),
          dataFim: dados["data_fim"] != null
              ? DateTime.parse(dados["data_fim"])
              : null,
          imagem: widget.obra.imagem, // mantém imagem local
          progresso: (dados["progresso"] ?? 0.0).toDouble(),
          ifcName: widget.obra.ifcName,
          ifcPath: widget.obra.ifcPath,
          ifcBytes: widget.obra.ifcBytes,
        );

        carregando = false;
      });
    } else {
      // Se der erro, usa os dados locais
      setState(() => carregando = false);
    }
  }

  // ===========================
  //  FORMATAÇÃO DE DATA
  // ===========================
  String _formatarData(DateTime data) {
    return "${data.day.toString().padLeft(2, '0')}/"
        "${data.month.toString().padLeft(2, '0')}/"
        "${data.year}";
  }

  // ===========================
  //  ITEM DE INFORMAÇÃO
  // ===========================
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
                Text(titulo,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text(valor,
                    style: const TextStyle(
                        fontSize: 14, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // sempre usa a mais atual (vinda do backend)
    final obra = obraAtualizada ?? widget.obra;

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
                  // STATUS + PROGRESSO
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

                  // DESCRIÇÃO
                  Text("Descrição",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Cores.azulMetro,
                      )),
                  const SizedBox(height: 6),
                  Text(
                    obra.descricao,
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),

                  const SizedBox(height: 24),

                  // INFORMAÇÕES
                  Text("Informações",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Cores.azulMetro,
                      )),
                  const SizedBox(height: 8),
                  _infoItem(Icons.location_on, "Localização", obra.localizacao),
                  _infoItem(Icons.engineering, "Responsável", obra.responsavel),
                  _infoItem(Icons.calendar_today, "Início",
                      _formatarData(obra.dataInicio)),
                  if (obra.dataFim != null)
                    _infoItem(Icons.flag, "Término",
                        _formatarData(obra.dataFim!)),

                  const SizedBox(height: 40),

                  // BOTÕES DE FOTO
                  Center(
                    child: Column(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add_a_photo, color: Colors.white),
                          label: const Text("Adicionar Fotos",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Cores.azulMetro,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EnviarImagem(obraId: obra.id),
                              ),
                            );
                            _carregarObra(); 
                          },
                        ),

                        const SizedBox(height: 12),

                        ElevatedButton.icon(
                          icon: const Icon(Icons.photo_library_outlined,
                              color: Colors.white),
                          label: const Text("Ver Fotos",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // EXCLUIR OBRA
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.white),
                      label: const Text("Excluir obra",
                          style:
                              TextStyle(color: Colors.white, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final confirmar = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Excluir obra"),
                            content: Text("Tem certeza que deseja excluir '${obra.nome}'?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancelar"),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Excluir"),
                              ),
                            ],
                          ),
                        );

                        if (confirmar != true) return;

                        final url = Uri.parse("http://127.0.0.1:8000/obras/${obra.id}");
                        final resp = await http.delete(url);

                        if (resp.statusCode == 200) {
                          Navigator.pop(context, 'deleted');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Erro ao excluir obra no servidor")),
                          );
                        }
                      }

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
