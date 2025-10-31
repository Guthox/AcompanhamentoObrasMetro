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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obras'),
        titleTextStyle: const TextStyle(color: Colors.white),
        backgroundColor: Cores.azulMetro,
      ),
      body: Container(
        color: Colors.grey[100],
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ObraDetalhe(obra: obraCard)),
        );
      },
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Center(
            child: Text(
              obraCard.nome,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Cores.azulMetro,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
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
          MaterialPageRoute(builder: (_) => ObraFormPage()),
        );

        if (novaObra != null && novaObra is Obras) {
          setState(() {
            obras.add(novaObra);
          });
        }
      },
      child: Card(
        elevation: 5,
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
