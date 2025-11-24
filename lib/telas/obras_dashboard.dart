import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:obras_view/telas/obra_detalhe.dart';
import 'package:obras_view/telas/obra_form.dart';
import 'package:obras_view/util/cores.dart';
import 'package:obras_view/util/obras.dart';

class ObrasDashboard extends StatefulWidget {
  const ObrasDashboard({Key? key}) : super(key: key);

  @override
  State<ObrasDashboard> createState() => _ObrasDashboardState();
}

class _ObrasDashboardState extends State<ObrasDashboard> {
  List<Obras> obras = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarObras();
  }

  Future<void> _carregarObras() async {
    final url = Uri.parse("http://127.0.0.1:8000/obras");

    final resp = await http.get(url);

    if (resp.statusCode == 200) {
      final lista = jsonDecode(resp.body);

      obras = lista.map<Obras>((o) {
        return Obras(
          id: o["id"],
          nome: o["nome"],
          descricao: o["descricao"],
          localizacao: o["localizacao"],
          responsavel: o["responsavel"],
          status: o["status"],
          dataInicio: DateTime.parse(o["data_inicio"]),
          dataFim: o["data_fim"] != null ? DateTime.parse(o["data_fim"]) : null,
          progresso: (o["progresso"] ?? 0.0).toDouble(),
          imagem: "assets/metro-sp-logo.png", // imagem padrão
          ifcName: "",
          ifcPath: "",
          ifcBytes: null,
        );
      }).toList();
    }

    setState(() => carregando = false);
  }

  // ======================================================
  //  BUILD
  // ======================================================
  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    int crossAxisCount = 2;
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
      appBar: AppBar(
        title: const Center(child: Text('Obras')),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        backgroundColor: Cores.azulMetro,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: obras.length + 1,
                itemBuilder: (context, index) {
                  if (index < obras.length) {
                    return _obraCard(context, obras[index]);
                  } else {
                    return _adicionarCard(context);
                  }
                },
              ),
            ),
    );
  }

  // ======================================================
  //  CARD DE OBRA
  // ======================================================
  Widget _obraCard(BuildContext context, Obras obraCard) {
    return GestureDetector(
      onTap: () async {
        final resultado = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ObraDetalhe(obra: obraCard)),
        );

        if (resultado == 'deleted') {
          setState(() => obras.remove(obraCard));
        } else {
          // Atualiza progresso quando voltar
          _carregarObras();
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            image: obraCard.imagem.isNotEmpty
                ? DecorationImage(
                    image: AssetImage(obraCard.imagem),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.4),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.black.withOpacity(0.5),
                  child: Text(
                    obraCard.nome,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================================================
  //  CARD ADICIONAR
  // ======================================================
  Widget _adicionarCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final novaObra = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ObraFormPage()),
        );

        if (novaObra != null && novaObra is Obras) {
          // Após criar, atualiza do banco
          _carregarObras();
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Cores.azulMetro.withOpacity(0.1),
        child: const Center(
          child: Icon(
            Icons.add_circle_outline,
            color: Colors.blueAccent,
            size: 48,
          ),
        ),
      ),
    );
  }
}
