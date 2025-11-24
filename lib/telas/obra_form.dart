import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:obras_view/util/cores.dart';
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

  PlatformFile? _ifcFile;

  // =============================== DATE PICKERS ===============================
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

  // =============================== PICK IFC ===============================
  Future<void> _selecionarIFC() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["ifc"],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() => _ifcFile = result.files.first);
    }
  }

  // =========================== ENVIA IFC PARA BACKEND ===========================
  Future<bool> enviarIFCParaBackend(int obraId) async {
    if (_ifcFile == null) return false;

    final uri = Uri.parse("http://127.0.0.1:8000/enviar_ifc");

    var request = http.MultipartRequest("POST", uri);
    request.fields["obra_id"] = obraId.toString();

    if (kIsWeb) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "ifc",
          _ifcFile!.bytes!,
          filename: _ifcFile!.name,
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(
          "ifc",
          _ifcFile!.path!,
          filename: _ifcFile!.name,
        ),
      );
    }

    final resposta = await request.send();
    return resposta.statusCode == 200;
  }

// =========================== ENVIA DADOS PARA O BANCO ===========================
  Future<bool> salvarDadosObraDB(int obraId) async {
      final uri = Uri.parse("http://127.0.0.1:8000/criar_obra");
      try {
        final response = await http.post(
            uri,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
                "id": obraId,
                "nome": _nomeController.text,
                "descricao": _descricaoController.text,
                "localizacao": _localizacaoController.text,
                "responsavel": _responsavelController.text,
                "status": _status,
                "data_inicio": (_dataInicio ?? DateTime.now()).toIso8601String(),
                "data_fim": _dataFim?.toIso8601String(),
            })
        );
        return response.statusCode == 200;
      } catch (e) {
        print("Erro DB: $e");
        return false;
      }
  }

  // =============================== BUILD ===================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("Cadastrar Obra")),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        backgroundColor: Cores.azulMetro,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Stack(
        children: [
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

          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              padding: const EdgeInsets.all(32),
              child: Card(
                elevation: 6,
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

  // =============================== FORM ===================================
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Text(
            "Informações da Obra",
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          _campoTexto(_nomeController, "Nome da obra"),
          _spacer(),

          _campoTexto(_descricaoController, "Descrição", maxLines: 3),
          _spacer(),

          _campoTexto(_localizacaoController, "Localização"),
          _spacer(),

          _campoTexto(_responsavelController, "Responsável"),
          _spacer(),

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

          _spacer(),

          // =============================== SELECT IFC ===============================
          OutlinedButton.icon(
            onPressed: _selecionarIFC,
            icon: const Icon(Icons.upload_file),
            label: Text(
              _ifcFile == null
                  ? "Selecionar arquivo IFC"
                  : "Selecionado: ${_ifcFile!.name}",
            ),
          ),

          const SizedBox(height: 30),

          // =============================== DATAS ===============================
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

          const SizedBox(height: 30),

          // =============================== SALVAR ===============================
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text("Salvar"),
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;

              if (_ifcFile == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecione um arquivo IFC")));
                return;
              }

              final obraId = DateTime.now().millisecondsSinceEpoch;

              // 1. SALVAR METADADOS NO BANCO (MySQL)
              final dbOk = await salvarDadosObraDB(obraId);
              if (!dbOk) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao salvar dados no banco.")));
                  return;
              }

              // 2. SALVAR ARQUIVO NO DISCO (Backend)
              final arqOk = await enviarIFCParaBackend(obraId);
              if (!arqOk) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao enviar arquivo IFC.")));
                   return;
              }

              // Sucesso total
              // Cria objeto local apenas para retorno da navegação (opcional)
               final obra = Obras(
                id: obraId,
                nome: _nomeController.text,
                descricao: _descricaoController.text,
                localizacao: _localizacaoController.text,
                status: _status,
                dataInicio: _dataInicio ?? DateTime.now(),
                dataFim: _dataFim,
                responsavel: _responsavelController.text,
                imagem: "assets/metro-sp-logo.png",
                progresso: 0.0,
                ifcName: _ifcFile!.name,
                ifcPath: kIsWeb ? null : _ifcFile!.path,
                ifcBytes: kIsWeb ? _ifcFile!.bytes : null,
              );

              final ok = await enviarIFCParaBackend(obraId);

              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Erro ao enviar IFC")),
                );
                return;
              }

              Navigator.pop(context, obra);
            },
          ),
        ],
      ),
    );
  }

  Widget _campoTexto(TextEditingController c, String label, {int maxLines = 1}) {
    return TextFormField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
      validator: (v) => v!.isEmpty ? "Campo obrigatório" : null,
    );
  }

  Widget _spacer() => const SizedBox(height: 16);
}
