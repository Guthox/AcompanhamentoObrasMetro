import 'package:flutter/material.dart';
import 'package:obras_view/telas/obra_detalhe.dart';
import 'package:obras_view/telas/obra_form.dart';
import 'package:obras_view/util/cores.dart';
import 'package:obras_view/util/info.dart';
import 'package:obras_view/util/obras.dart';

class ObrasDashboard extends StatefulWidget {
  const ObrasDashboard({Key? key}) : super(key: key);

  @override
  State<ObrasDashboard> createState() => _ObrasDashboardState();
}

class _ObrasDashboardState extends State<ObrasDashboard> {
  List<Obras> obras = Info.listaObras;

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    // ajuste colunas dependendo do tamanho da tela
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
      ),
      body: Container(
        color: Colors.grey[100],
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2, // levemente retangular
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

  Widget _obraCard(BuildContext context, Obras obraCard) {
  return GestureDetector(
    onTap: () async {
      // Navega para a tela de detalhes e aguarda um possível retorno
      final resultado = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ObraDetalhe(obra: obraCard)),
      );

      // Se o detalhe retornar 'deleted', removemos do dashboard
      if (resultado == 'deleted') {
        setState(() {
          obras.remove(obraCard);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Obra '${obraCard.nome}' excluída com sucesso."),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 2),
          ),
        );
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


  Widget _adicionarCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final novaObra = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ObraFormPage()),
        );

        if (novaObra != null && novaObra is Obras) {
          setState(() {
            obras.add(novaObra);
          });
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
