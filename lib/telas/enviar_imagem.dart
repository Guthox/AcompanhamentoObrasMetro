import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:obras_view/util/cores.dart';

class EnviarImagem extends StatefulWidget {
  final int obraId;
  const EnviarImagem({super.key, required this.obraId});

  @override
  _EnviarImagemState createState() => _EnviarImagemState();
}

class _EnviarImagemState extends State<EnviarImagem> {
  final ImagePicker _picker = ImagePicker();

  File? _fotoLocal;
  Uint8List? _fotoWeb;

  bool carregando = false;

  Future<void> _selecionarImagem() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery);

    if (img != null) {
      if (kIsWeb) {
        _fotoWeb = await img.readAsBytes();
      } else {
        _fotoLocal = File(img.path);
      }
      setState(() {});
    }
  }

  Future<void> _tirarFoto() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.camera);

    if (img != null) {
      if (kIsWeb) {
        _fotoWeb = await img.readAsBytes();
      } else {
        _fotoLocal = File(img.path);
      }
      setState(() {});
    }
  }

  Future<void> _enviarParaBackend() async {
    final bool semImagem =
        (!kIsWeb && _fotoLocal == null) || (kIsWeb && _fotoWeb == null);

    if (semImagem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione uma imagem primeiro")),
      );
      return;
    }

    setState(() => carregando = true);

    final uri = Uri.parse("http://127.0.0.1:8000/analisar");

    var request = http.MultipartRequest("POST", uri);
    request.fields["obra_id"] = widget.obraId.toString();

    if (kIsWeb) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "foto",
          _fotoWeb!,
          filename: "upload.jpg",
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath("foto", _fotoLocal!.path),
      );
    }

    final resposta = await request.send();
    final body = await resposta.stream.bytesToString();

    setState(() => carregando = false);

    if (resposta.statusCode == 200) {
      final dados = jsonDecode(body);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultadoAnalise(dados: dados),
        ),
      );

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro no backend: ${resposta.statusCode}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget preview;

    if (_fotoWeb != null) {
      preview = Image.memory(_fotoWeb!, fit: BoxFit.cover);
    } else if (_fotoLocal != null) {
      preview = Image.file(_fotoLocal!, fit: BoxFit.cover);
    } else {
      preview = const Center(child: Text("Nenhuma foto selecionada."));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Enviar Foto da Obra"),
        backgroundColor: Cores.azulMetro,
      ),
      body: Column(
        children: [
          Expanded(child: preview),

          if (carregando) const LinearProgressIndicator(),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: _selecionarImagem,
                  icon: const Icon(Icons.photo),
                  label: const Text("Galeria"),
                ),
                ElevatedButton.icon(
                  onPressed: _tirarFoto,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Câmera"),
                ),
                ElevatedButton.icon(
                  onPressed: carregando ? null : _enviarParaBackend,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text("Enviar"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ResultadoAnalise extends StatelessWidget {
  final Map dados;

  const ResultadoAnalise({super.key, required this.dados});

  @override
  Widget build(BuildContext context) {
    final progresso = (dados["progresso_total"] * 100).toStringAsFixed(2);

    final String imagem = dados["imagem_anotada"];
    final String url = "http://localhost:8000/resultados/$imagem?v=${DateTime.now().millisecondsSinceEpoch}";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Resultado da Análise"),
        backgroundColor: Cores.azulMetro,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Progresso total da obra:",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              "$progresso%",
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 25),

            const Text(
              "Imagem analisada:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: Image.network(
                url,
                key: ValueKey(url),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                  const Center(child: Text("Erro ao carregar imagem")),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

