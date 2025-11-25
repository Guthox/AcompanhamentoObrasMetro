// ignore_for_file: deprecated_member_use, library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:obras_view/util/cores.dart';
import 'package:obras_view/util/obras.dart';

class ObraFormContent extends StatefulWidget {
  const ObraFormContent({super.key});

  @override
  _ObraFormContentState createState() => _ObraFormContentState();
}

class _ObraFormContentState extends State<ObraFormContent> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _localizacaoController = TextEditingController();
  final _responsavelController = TextEditingController();

  DateTime? _dataInicio;
  DateTime? _dataFim;
  String _status = 'Em andamento';

  PlatformFile? _ifcFile;
  bool _isUploading = false; // Para mostrar loading no botão

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

  // =========================== ENVIA IFC ===========================
  Future<bool> enviarIFCParaBackend(int obraId) async {
    if (_ifcFile == null) return false;

    // Ajuste o IP se necessário (ex: 10.0.2.2 para emulador Android)
    final uri = Uri.parse("http://127.0.0.1:8000/enviar_ifc");

    var request = http.MultipartRequest("POST", uri);
    request.fields["obra_id"] = obraId.toString();

    if (kIsWeb) {
      request.files.add(
        http.MultipartFile.fromBytes("ifc", _ifcFile!.bytes!, filename: _ifcFile!.name),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath("ifc", _ifcFile!.path!, filename: _ifcFile!.name),
      );
    }

    try {
      final resposta = await request.send();
      return resposta.statusCode == 200;
    } catch (e) {
      // print("Erro upload: $e");
      return false;
    }
  }

  // =============================== BUILD ===================================
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600, // Largura fixa para o modal ficar bonito
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Ocupa só o espaço necessário
        children: [
          // --- CABEÇALHO DO MODAL ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Cadastrar Nova Obra",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Cores.azulMetro,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),

          // --- CONTEÚDO ROLÁVEL ---
          Flexible(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _campoTexto(_nomeController, "Nome da obra", Icons.apartment),
                    _spacer(),
                    _campoTexto(_descricaoController, "Descrição", Icons.description, maxLines: 3),
                    _spacer(),
                    _campoTexto(_localizacaoController, "Localização", Icons.location_on),
                    _spacer(),
                    _campoTexto(_responsavelController, "Responsável", Icons.person),
                    _spacer(),

                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: InputDecoration(
                        labelText: "Status",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.flag),
                      ),
                      items: const [
                        DropdownMenuItem(value: "Em andamento", child: Text("Em andamento")),
                        DropdownMenuItem(value: "Concluída", child: Text("Concluída")),
                        DropdownMenuItem(value: "Parada", child: Text("Parada")),
                      ],
                      onChanged: (value) => setState(() => _status = value!),
                    ),
                    _spacer(),

                    // Datas lado a lado
                    Row(
                      children: [
                        Expanded(child: _botaoData(true)),
                        const SizedBox(width: 16),
                        Expanded(child: _botaoData(false)),
                      ],
                    ),
                    _spacer(),

                    // Seleção de Arquivo IFC
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade50,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.folder_open, color: Cores.azulMetro),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Arquivo IFC (Modelo 3D)", style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  _ifcFile == null ? "Nenhum arquivo selecionado" : _ifcFile!.name,
                                  style: TextStyle(color: _ifcFile == null ? Colors.grey : Colors.green, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _selecionarIFC,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black),
                            child: const Text("Escolher"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --- BOTÃO SALVAR ---
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Cores.azulMetro,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isUploading ? null : () async {
                if (!_formKey.currentState!.validate()) return;

                if (_ifcFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecione um arquivo IFC")));
                  return;
                }

                setState(() => _isUploading = true);

                final obraId = DateTime.now().millisecondsSinceEpoch;

                final ok = await enviarIFCParaBackend(obraId);

                if (!ok) {
                  setState(() => _isUploading = false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao enviar IFC para o servidor")));
                  return;
                }

                final obra = Obras(
                  id: obraId,
                  nome: _nomeController.text,
                  descricao: _descricaoController.text,
                  localizacao: _localizacaoController.text,
                  status: _status,
                  dataInicio: _dataInicio ?? DateTime.now(),
                  dataFim: _dataFim,
                  responsavel: _responsavelController.text,
                  imagem: "assets/metro-sp-logo.png", // Imagem padrão
                  progresso: 0.0,
                  ifcName: _ifcFile!.name,
                  ifcPath: kIsWeb ? null : _ifcFile!.path,
                  ifcBytes: kIsWeb ? _ifcFile!.bytes : null,
                );

                Navigator.pop(context, obra); // Retorna a obra criada
              },
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Cadastrar Obra", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campoTexto(TextEditingController c, String label, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: Icon(icon),
      ),
      maxLines: maxLines,
      validator: (v) => v!.isEmpty ? "Campo obrigatório" : null,
    );
  }

  Widget _botaoData(bool isInicio) {
    final data = isInicio ? _dataInicio : _dataFim;
    final label = isInicio ? "Início" : "Fim";
    
    return InkWell(
      onTap: isInicio ? _selecionarDataInicio : _selecionarDataFim,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
            const SizedBox(width: 10),
            Text(
              data == null ? label : DateFormat('dd/MM/yyyy').format(data),
              style: TextStyle(color: data == null ? Colors.grey[600] : Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _spacer() => const SizedBox(height: 16);
}