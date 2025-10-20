import 'package:flutter/material.dart';
import 'package:obras_view/telas/obra_detalhe.dart';
import 'package:obras_view/util/cores.dart';
import 'package:obras_view/util/obras.dart';

class ObrasDashboard extends StatelessWidget {
  // Lista de obras 
  final List<Obras> obras = [
    Obras(
      id: 1,
      nome: 'Linha 6 - Laranja',
      descricao: 'Construção do túnel principal e estações centrais.',
      localizacao: 'Zona Norte - São Paulo',
      status: 'Em andamento',
      dataInicio: DateTime(2020, 5, 1),
      responsavel: 'Construtora ABC',
      imagem: 'assets/metro-sp-logo.png',
      progresso: 0.7,
    ),
    Obras(
      id: 2,
      nome: 'Reforma Estação Sé',
      descricao: 'Reforço estrutural e modernização dos acessos.',
      localizacao: 'Centro - São Paulo',
      status: 'Concluída',
      dataInicio: DateTime(2018, 2, 15),
      dataFim: DateTime(2021, 10, 30),
      responsavel: 'Construtora XYZ',
      imagem: 'assets/metro-sp-logo.png',
      progresso: 1.0,
    ),
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

  Widget _obraCard(BuildContext context, Obras obraCard) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ObraDetalhe(obra: obraCard,)),
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
