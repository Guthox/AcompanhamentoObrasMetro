import 'package:flutter/material.dart';
import 'package:obras_view/util/cores.dart';

class ObrasDashboard extends StatelessWidget {
  // Lista de obras 
  // TODO obter a lista do servidor ou algo do tipo
  final List<String> obras = [
    'Linha 6 - Laranja',
    'Expansão Linha 2 - Verde',
    'Reforma Estação Sé',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obras'),
        titleTextStyle: TextStyle(color: Colors.white),
        backgroundColor: Cores.azulMetro,
      ),
      body: Container(
        color: Colors.grey[100],
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 cards por linha
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1, // quadrados
          ),
          itemCount: obras.length + 1, // +1 pro card "adicionar"
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

  Widget _obraCard(BuildContext context, String nomeObra) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ObraDetalhe(nomeObra: nomeObra)),
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
              nomeObra,
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NovaObra()),
        );
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

// ====== TELAS DE DESTINO ======
// TODO mostrar detalhes das obras
class ObraDetalhe extends StatelessWidget {
  final String nomeObra;

  const ObraDetalhe({required this.nomeObra, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(nomeObra),
        backgroundColor: Cores.azulMetro,
      ),
      body: Center(
        child: Text(
          'Detalhes da obra: $nomeObra',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

// TODO fazer formulario para adicionar obras
class NovaObra extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Nova Obra'),
        backgroundColor: Cores.azulMetro,
      ),
      body: const Center(
        child: Text(
          'Formulário para adicionar nova obra',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
