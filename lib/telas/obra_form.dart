import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:obras_view/util/cores.dart';
import 'package:obras_view/util/info.dart';
import 'package:obras_view/util/obras.dart';

class ObraFormPage extends StatefulWidget {
  const ObraFormPage({super.key});

  @override
  _ObraFormPageState createState() => _ObraFormPageState();
}

class _ObraFormPageState extends State<ObraFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _localizacaoController = TextEditingController();
  final _responsavelController = TextEditingController();
  DateTime? _dataInicio;
  DateTime? _dataFim;
  String _status = 'Em andamento';

  Future<void> _selecionarDataInicio() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (data != null) setState(() => _dataInicio = data);
  }

  Future<void> _selecionarDataFim() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (data != null) setState(() => _dataFim = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("Cadastrar Obra")),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        backgroundColor: Cores.azulMetro,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // =============================
      //     FUNDO + FORMULÁRIO
      // =============================
      body: Stack(
        children: [
          // ---- FUNDO COM IMAGEM ----
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage("foto-metro-sp.jpg"),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.25),
                  BlendMode.darken,
                ),
              ),
            ),
          ),

          // ---- FORMULÁRIO EM CARD ----
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              padding: const EdgeInsets.all(32),
              child: Card(
                elevation: 6,
                shadowColor: Colors.black45,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================
  //         FORM COMPLETO
  // =============================
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Informações da Obra",
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Nome
          TextFormField(
            controller: _nomeController,
            decoration: const InputDecoration(
              labelText: "Nome da obra",
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? "Informe o nome da obra" : null,
          ),
          const SizedBox(height: 16),

          // Descrição
          TextFormField(
            controller: _descricaoController,
            decoration: const InputDecoration(
              labelText: "Descrição",
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) =>
                value == null || value.isEmpty ? "Informe a descrição" : null,
          ),
          const SizedBox(height: 16),

          // Localização
          TextFormField(
            controller: _localizacaoController,
            decoration: const InputDecoration(
              labelText: "Localização",
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? "Informe a localização" : null,
          ),
          const SizedBox(height: 16),

          // Responsável
          TextFormField(
            controller: _responsavelController,
            decoration: const InputDecoration(
              labelText: "Responsável",
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? "Informe o responsável" : null,
          ),
          const SizedBox(height: 16),

          // Status
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(
              labelText: "Status",
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: "Em andamento", child: Text("Em andamento")),
              DropdownMenuItem(value: "Concluída", child: Text("Concluída")),
              DropdownMenuItem(value: "Parada", child: Text("Parada")),
            ],
            onChanged: (value) => setState(() => _status = value!),
          ),
          const SizedBox(height: 16),

          // Datas
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _selecionarDataInicio,
                  child: Text(
                    _dataInicio == null
                        ? "Selecionar Data Início"
                        : "Início: ${DateFormat('dd/MM/yyyy').format(_dataInicio!)}",
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: _selecionarDataFim,
                  child: Text(
                    _dataFim == null
                        ? "Selecionar Data Fim"
                        : "Fim: ${DateFormat('dd/MM/yyyy').format(_dataFim!)}",
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Botão Salvar
          ElevatedButton.icon(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final obra = Obras(
                  id: DateTime.now().millisecondsSinceEpoch,
                  nome: _nomeController.text,
                  descricao: _descricaoController.text,
                  localizacao: _localizacaoController.text,
                  status: _status,
                  dataInicio: _dataInicio ?? DateTime.now(),
                  dataFim: _dataFim,
                  responsavel: _responsavelController.text,
                  imagem: "assets/metro-sp-logo.png",
                  progresso: 0.0,
                );

                Navigator.pop(context, obra);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Obra salva com sucesso!")),
                );
              }
            },
            icon: const Icon(Icons.save),
            label: const Text("Salvar"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
