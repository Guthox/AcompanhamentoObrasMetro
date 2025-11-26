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

    // ENVIA O ID DA OBRA CORRETAMENTE
    request.fields["obra_id"] = widget.obraId.toString();

    // ENVIA O ARQUIVO COMO "file" — o nome EXATO que seu backend exige
    if (kIsWeb) {
      request.files.add(
        http.MultipartFile.fromBytes(
          "foto",         //
          _fotoWeb!,
          filename: "upload.jpg",
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(
          "foto",         //
          _fotoLocal!.path,
        ),
      );
    }


    final resposta = await request.send();
    final body = await resposta.stream.bytesToString();

    setState(() => carregando = false);

    if (resposta.statusCode == 200) {
  final dados = jsonDecode(body);

  final atualizado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultadoAnalise(dados: dados),
      ),
    );

    if (atualizado == true) {
      Navigator.pop(context, true); // avisa VisaoGeral para atualizar
    }
    return;
  }
 else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro no backend: ${resposta.statusCode} - $body"),
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
        title: const Center(child: Text("Enviar foto da obra")),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        iconTheme: const IconThemeData(color: Colors.white),
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
    final larguraTela = MediaQuery.of(context).size.width;

    // 1. Extração de dados do JSON novo
    // Progresso
    String progressoRaw = "0";
    if (dados["dados_ifc"] != null && dados["dados_ifc"]["progresso_calculado"] != null) {
      progressoRaw = dados["dados_ifc"]["progresso_calculado"].toString();
    } else if (dados["progresso_total"] != null) {
      progressoRaw = dados["progresso_total"].toString();
    }
    
    double progressoVal = (double.tryParse(progressoRaw) ?? 0.0) / 100.0;
    String porcentagemTexto = progressoRaw;

    // URL da Imagem
    String? imageUrl = dados["imagem_anotada_url"];
    // Fallback para versões antigas do backend
    if (imageUrl == null && dados["imagem_anotada"] != null) {
      final nome = dados["imagem_anotada"];
      imageUrl = "http://127.0.0.1:8000/resultados/$nome";
    }

    // Estatísticas (O que foi detectado)
    final Map estatisticas = dados["estatisticas_real"] ?? {};

    // Informação de contexto (Câmera ou IFC Total)
    final String baseUsada = dados["dados_ifc"]?["base_usada"] ?? "Análise Geral";

    return Scaffold(
     appBar: AppBar(
      title: const Center(child: Text("Resultado da Análise")),
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      backgroundColor: Cores.azulMetro,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context, true),
      ),
    ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // --- TÍTULO E CONTEXTO ---
            Row(
              children: [
                const Icon(Icons.analytics_outlined, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  "Relatório de IA",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Cores.azulMetro),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 4),
              child: Text(
                "Base de cálculo: $baseUsada",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),

            // --- IMAGEM (Visual Limpo igual CameraView) ---
            Container(
              width: double.infinity,
              height: 400, // Altura fixa ou responsiva
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain, // Contain para ver a foto toda sem cortes
                        loadingBuilder: (ctx, child, p) {
                          if (p == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (ctx, err, stack) => const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            Text("Erro ao carregar imagem"),
                          ],
                        ),
                      )
                    : const Center(child: Text("Nenhuma imagem retornada")),
              ),
            ),

            const SizedBox(height: 30),

            // --- BARRA DE PROGRESSO ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Progresso Estimado", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  "$porcentagemTexto%",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: progressoVal >= 1.0 ? Colors.green : Cores.azulMetro,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progressoVal > 1.0 ? 1.0 : progressoVal,
                minHeight: 15,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  progressoVal >= 1.0 ? Colors.green : Cores.azulMetro,
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text("Itens Identificados", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // --- GRID DE ESTATÍSTICAS (Estilo CameraView) ---
            if (estatisticas.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: larguraTela > 860 ? 4 : larguraTela > 680 ? 3 : larguraTela > 350 ? 2 : 1,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 80,
                ),
                itemCount: estatisticas.length,
                itemBuilder: (context, index) {
                  final entry = estatisticas.entries.elementAt(index);
                  final nome = entry.key.toString();
                  final qtd = entry.value.toString();

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      // Borda azul padrão pois aqui não temos o "planejado" para saber se ficou verde
                      border: Border.all(
                        color: Cores.azulMetro.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Ícone genérico de "Check" ou "Olho"
                        Icon(
                          Icons.visibility_outlined,
                          size: 28,
                          color: Cores.azulMetro,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nome.toUpperCase(),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                  children: [
                                    TextSpan(
                                      text: "$qtd itens",
                                      style: TextStyle(color: Cores.azulMetro),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("Nenhum objeto identificado pela IA."),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}