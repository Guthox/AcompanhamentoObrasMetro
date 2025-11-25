// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:obras_view/telas/obra_detalhe.dart';
import 'package:obras_view/telas/obra_form.dart'; // Certifique-se que este arquivo tem o ObraFormContent
import 'package:obras_view/util/cores.dart';
import 'package:obras_view/util/obras.dart';

class ObrasDashboard extends StatefulWidget {
  const ObrasDashboard({super.key});

  @override
  State<ObrasDashboard> createState() => _ObrasDashboardState();
}

class _ObrasDashboardState extends State<ObrasDashboard> {
  // Variáveis de Estado
  List<Obras> obras = [];
  List<Obras> obrasFiltradas = [];
  bool carregando = true;
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarObras(); // Carrega ao iniciar
  }

  // --- BUSCA DADOS DO BACKEND ---
  Future<void> _carregarObras() async {
    setState(() => carregando = true);

    try {
      // Ajuste o IP se necessário (10.0.2.2 para emulador Android)
      final url = Uri.parse("http://127.0.0.1:8000/obras");
      final resp = await http.get(url);

      if (resp.statusCode == 200) {
        final lista = jsonDecode(resp.body);

        final listaObras = lista.map<Obras>((o) {
          return Obras(
            id: o["id"],
            nome: o["nome"] ?? "Sem nome",
            descricao: o["descricao"] ?? "",
            localizacao: o["localizacao"] ?? "",
            responsavel: o["responsavel"] ?? "",
            status: o["status"] ?? "Em andamento",
            dataInicio: DateTime.parse(o["data_inicio"]),
            dataFim: o["data_fim"] != null ? DateTime.parse(o["data_fim"]) : null,
            progresso: (o["progresso"] ?? 0.0).toDouble(),
            imagem: "assets/metro-sp-logo.png",
            ifcName: "",
            ifcPath: "",
            ifcBytes: null,
          );
        }).toList();

        setState(() {
          obras = listaObras;
          _filtrarObras(_searchController.text);
          carregando = false;
        });
      } else {
        setState(() => carregando = false);
        print("Erro ao carregar obras: ${resp.statusCode}");
      }
    } catch (e) {
      setState(() => carregando = false);
      print("Erro de conexão: $e");
    }
  }

  // --- FILTRO DE PESQUISA ---
  void _filtrarObras(String query) {
    setState(() {
      if (query.isEmpty) {
        obrasFiltradas = List.from(obras);
      } else {
        obrasFiltradas = obras.where((obra) {
          final nome = (obra.nome).toLowerCase();
          final local = (obra.localizacao).toLowerCase();
          final q = query.toLowerCase();
          return nome.contains(q) || local.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    // Responsividade do Grid
    int crossAxisCount;
    if (largura > 1600) {
      crossAxisCount = 5;
    } else if (largura > 1200) {
      crossAxisCount = 4;
    } else if (largura > 800) {
      crossAxisCount = 3;
    } else if (largura > 600) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            const Text("Minhas Obras", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            if (!carregando)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${obras.length}",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              )
          ],
        ),
        backgroundColor: Cores.azulMetro,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarObras,
            tooltip: "Recarregar",
          )
        ],
      ),
      body: Column(
        children: [
          // 1. BARRA DE PESQUISA
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filtrarObras,
              decoration: InputDecoration(
                labelText: "Buscar obra",
                hintText: "Digite o nome ou local...",
                labelStyle: const TextStyle(color: Colors.grey),
                floatingLabelStyle: TextStyle(color: Cores.azulMetro),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                // Borda normal (cinza)
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
                ),
                // Borda focada (azul)
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Cores.azulMetro, width: 2.0),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _filtrarObras('');
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // 2. GRID DE OBRAS
          Expanded(
            child: carregando
                ? Center(child: CircularProgressIndicator(color: Cores.azulMetro))
                : obrasFiltradas.isEmpty && _searchController.text.isNotEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 280, // Altura Fixa
                        ),
                        itemCount: obrasFiltradas.length + 1,
                        itemBuilder: (context, index) {
                          if (index < obrasFiltradas.length) {
                            return _obraCard(context, obrasFiltradas[index]);
                          } else {
                            // O botão adicionar só aparece se não estiver buscando
                            return _searchController.text.isEmpty
                                ? _adicionarCard(context)
                                : const SizedBox();
                          }
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // --- CARD DA OBRA ---
  Widget _obraCard(BuildContext context, Obras obraCard) {
    bool temImagem = obraCard.imagem.isNotEmpty;
    
    // Lógica de Prazo e Status
    int diasRestantes = 0;
    String textoPrazo = "Sem prazo";
    Color corPrazo = Colors.grey;
    
    if (obraCard.dataFim != null) {
      final hoje = DateTime.now();
      final dataFim = DateTime(obraCard.dataFim!.year, obraCard.dataFim!.month, obraCard.dataFim!.day);
      final dataInicio = DateTime(obraCard.dataInicio.year, obraCard.dataInicio.month, obraCard.dataInicio.day);
      final dataHoje = DateTime(hoje.year, hoje.month, hoje.day);
      
      final prazoTotal = dataFim.difference(dataInicio).inDays;
      final diasPassados = dataHoje.difference(dataInicio).inDays;
      diasRestantes = dataFim.difference(dataHoje).inDays;
      
      if (diasRestantes < 0) {
        textoPrazo = "${diasRestantes.abs()} dias de atraso";
      } else if (diasRestantes == 0) {
        textoPrazo = "Acaba hoje";
      } else {
        textoPrazo = "$diasRestantes dias restantes";
      }

      // Cor do prazo baseada no andamento
      if (obraCard.progresso >= 1.0) {
         corPrazo = Colors.green; 
      } else if (diasRestantes < 0) {
         corPrazo = Colors.red; 
      } else if (prazoTotal > 0) {
         double progressoEsperado = diasPassados / prazoTotal;
         if (progressoEsperado > 1.0) progressoEsperado = 1.0;
         if (progressoEsperado < 0.0) progressoEsperado = 0.0;

         if (obraCard.progresso < progressoEsperado) {
           corPrazo = Colors.red; // Atrasado no cronograma
         } else {
           corPrazo = Colors.green; // Em dia
         }
      }
    }

    String statusText = obraCard.status;

    return Hero(
      tag: 'obra_img_${obraCard.id}',
      child: _HoverScaleCard(
        onTap: () async {
          final resultado = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ObraDetalhe(obra: obraCard)),
          );

          // Recarrega sempre ao voltar (para atualizar progresso ou remoção)
          await _carregarObras();

          if (resultado == 'deleted') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Obra '${obraCard.nome}' removida."),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. IMAGEM
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: temImagem
                      ? Image.asset(
                          obraCard.imagem,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: const Icon(Icons.image_not_supported)),
                        )
                      : Container(
                          color: Cores.azulMetro.withOpacity(0.1),
                          child: Icon(Icons.apartment, size: 40, color: Cores.azulMetro.withOpacity(0.3)),
                        ),
                ),
              ),

              // 2. INFORMAÇÕES
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Título e Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              obraCard.nome,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _corStatus(statusText).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              statusText.toUpperCase(),
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _corStatus(statusText)),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Localização
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.grey, size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              obraCard.localizacao,
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Prazo
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: corPrazo),
                          const SizedBox(width: 4),
                          Text(
                            textoPrazo,
                            style: TextStyle(fontSize: 11, color: corPrazo, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Barra de Progresso
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: obraCard.progresso,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  obraCard.progresso >= 1.0 ? Colors.green : Cores.azulMetro
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${(obraCard.progresso * 100).toInt()}%",
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Cores.azulMetro),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- CARD DE ADICIONAR (MODAL) ---
  Widget _adicionarCard(BuildContext context) {
    return _HoverScaleCard(
      onTap: () async {
        final novaObra = await showDialog<Obras>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Dialog(
              backgroundColor: Colors.transparent, 
              insetPadding: EdgeInsets.all(10),
              child: ObraFormContent(), // Seu componente de formulário
            );
          },
        );

        if (novaObra != null) {
          await _carregarObras(); // Recarrega do banco para ter certeza
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Obra cadastrada com sucesso!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Cores.azulMetro.withOpacity(0.3), width: 2),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Cores.azulMetro.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.add, color: Cores.azulMetro, size: 32),
            ),
            const SizedBox(height: 16),
            Text("Nova Obra", style: TextStyle(color: Cores.azulMetro, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text("Nenhuma obra encontrada", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }

  Color _corStatus(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'concluída': return Colors.green;
      case 'atrasada': return Colors.red;
      case 'em andamento': return Colors.blue;
      default: return Colors.orange;
    }
  }
}

// --- WIDGET HOVER ---
class _HoverScaleCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _HoverScaleCard({required this.child, required this.onTap});

  @override
  State<_HoverScaleCard> createState() => _HoverScaleCardState();
}

class _HoverScaleCardState extends State<_HoverScaleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}