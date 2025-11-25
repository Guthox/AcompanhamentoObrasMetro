// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_selector/file_selector.dart';
import 'package:obras_view/util/cameras.dart';
import 'package:obras_view/util/components/obra_detalhe/camera_form.dart';
import 'package:obras_view/util/components/obra_detalhe/camera_view.dart';
import 'package:obras_view/util/components/obra_detalhe/menu_lateral.dart';
import 'package:obras_view/util/components/obra_detalhe/visao_geral.dart';
import 'package:obras_view/util/imagens.dart';
import 'package:obras_view/util/info.dart';
import '../util/cores.dart';
import '../util/obras.dart';

class ObraDetalhe extends StatefulWidget {
  final Obras obra;
  const ObraDetalhe({required this.obra, super.key});

  @override
  State<ObraDetalhe> createState() => _ObraDetalheState();
}

class _ObraDetalheState extends State<ObraDetalhe> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Estado
  int _indiceSelecionado = 0;
  Cameras? _cameraSelecionada;
  List<Cameras> listaCameras = [];
  bool _isProcessing = false;
  double _opacidadeOverlay = 0.5;
  bool _mostrarAnotacoesIA = false;

  // Controllers
  final TextEditingController _angXController = TextEditingController();
  final TextEditingController _angYController = TextEditingController();
  final TextEditingController _zoomController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();

  final String baseUrl = "http://127.0.0.1:8000";

  @override
  void initState() {
    super.initState();
    _carregarCamerasDoBanco(); // [NOVO] Carrega ao iniciar
  }

  @override
  void dispose() {
    _angXController.dispose();
    _angYController.dispose();
    _zoomController.dispose();
    _nomeController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE NEGÓCIO ---

  Future<void> _carregarCamerasDoBanco() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/cameras/${widget.obra.id}"));
      if (response.statusCode == 200) {
        final List<dynamic> dados = jsonDecode(response.body);
        setState(() {
          listaCameras = dados.map((json) => Cameras(
            id: json['id'],
            obraId: widget.obra.id,
            nome: json['nome'],
            anguloX: (json['angulo_x'] as num).toDouble(),
            anguloY: (json['angulo_y'] as num).toDouble(),
            zoom: (json['zoom'] as num).toDouble(),
            renderUrl: json['render_url'],
            estatisticas: json['estatisticas'],
            estatisticasReal: json['estatisticas_real'],
            renderRealAnotadoUrl: json['render_real_anotado_url'],
          )).toList();
          // Atualiza a lista global do Info para o VisaoGeral usar
          Info.listaCameras = listaCameras; 
        });
      }
    } catch (e) {
      print("Erro ao carregar câmeras: $e");
    }
  }

Future<void> _excluirCameraAtual() async {
    if (_cameraSelecionada == null) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Câmera"),
        content: Text("Tem certeza que deseja excluir '${_cameraSelecionada!.nome}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Cores.azulMetro), 
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Excluir", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await http.delete(Uri.parse("$baseUrl/cameras/${_cameraSelecionada!.id}"));
        
        setState(() {
          listaCameras.removeWhere((c) => c.id == _cameraSelecionada!.id);
          Info.listaCameras = listaCameras;
          _cameraSelecionada = null;
          _indiceSelecionado = 0;
        });

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Câmera excluída com sucesso.")));

        await _recarregarDadosObra();

      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erro ao excluir."), backgroundColor: Colors.red));
      }
    }
  }
  Future<void> _adicionarImagemReal() async {
    if (_cameraSelecionada == null) return;
    try {
      const XTypeGroup typeGroup = XTypeGroup(label: 'images', extensions: <String>['jpg', 'png', 'jpeg']);
      final XFile? photo = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
      
      if (photo != null) {
        // Apenas para mostrar na tela antes de enviar (opcional, pode remover se quiser só usar a URL)
        final novaImagem = Imagens(localPath: photo.path, cameraId: _cameraSelecionada!.id);
        setState(() => Info.addImagem(novaImagem));

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Analisando progresso na imagem...")));

        // Usa a NOVA ROTA específica para câmera
        var uri = Uri.parse("$baseUrl/analisar_foto_real_camera");
        var request = http.MultipartRequest('POST', uri);
        request.fields['camera_id'] = _cameraSelecionada!.id.toString();
        
        if (kIsWeb) {
           request.files.add(http.MultipartFile.fromBytes('file', await photo.readAsBytes(), filename: 'upload.jpg'));
        } else {
           request.files.add(await http.MultipartFile.fromPath('file', photo.path));
        }

        var response = await request.send();
        
        if (response.statusCode == 200) {
           var responseData = await http.Response.fromStream(response);
           var data = jsonDecode(responseData.body);
           var statsReal = data['estatisticas_real'] as Map<String, dynamic>;
           var urlAnotada = data['imagem_anotada_url'] as String?; 

           Cameras cameraAtualizada = Cameras(
             id: _cameraSelecionada!.id, nome: _cameraSelecionada!.nome, anguloX: _cameraSelecionada!.anguloX, anguloY: _cameraSelecionada!.anguloY, zoom: _cameraSelecionada!.zoom, obraId: _cameraSelecionada!.obraId, renderUrl: _cameraSelecionada!.renderUrl, estatisticas: _cameraSelecionada!.estatisticas,
             estatisticasReal: statsReal, renderRealAnotadoUrl: urlAnotada, 
           );

           setState(() {
             int index = listaCameras.indexWhere((c) => c.id == _cameraSelecionada!.id);
             if (index != -1) listaCameras[index] = cameraAtualizada;
             Info.listaCameras = listaCameras; // Atualiza global
             _cameraSelecionada = cameraAtualizada;
             _mostrarAnotacoesIA = true; 
           });
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Análise concluída!"), backgroundColor: Colors.green));
        } else {
           throw Exception("Erro API");
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _salvarCamera() async {
    if (_angXController.text.isNotEmpty && _angYController.text.isNotEmpty && _zoomController.text.isNotEmpty) {
      setState(() => _isProcessing = true);
      final anguloX = double.tryParse(_angXController.text) ?? 0.0;
      final anguloY = double.tryParse(_angYController.text) ?? 0.0;
      final zoom = double.tryParse(_zoomController.text) ?? 10.0;
      final nomeCamera = _nomeController.text;

      try {
        // 1. Renderiza (Para pegar a imagem e stats esperados)
        var uriRender = Uri.parse("$baseUrl/renderizar_camera");
        var reqRender = http.MultipartRequest('POST', uriRender)
          ..fields['obra_id'] = widget.obra.id.toString()
          ..fields['azimuth'] = anguloX.toString()
          ..fields['elevation'] = anguloY.toString()
          ..fields['zoom'] = zoom.toString();

        var resRenderStream = await reqRender.send();
        var resRender = await http.Response.fromStream(resRenderStream);

        if (resRender.statusCode == 200) {
          final data = jsonDecode(resRender.body);
          final imageUrl = data['image_url'];
          final stats = data['estatisticas'];

          // 2. Salva no Banco
          var uriSalvar = Uri.parse("$baseUrl/salvar_camera");
          var resSalvar = await http.post(
            uriSalvar,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "obra_id": widget.obra.id,
              "nome": nomeCamera,
              "angulo_x": anguloX,
              "angulo_y": anguloY,
              "zoom": zoom,
              "render_url": imageUrl,
              "estatisticas": stats
            })
          );

          if (resSalvar.statusCode == 200) {
             final dadosSalvos = jsonDecode(resSalvar.body);
             final novoId = dadosSalvos['id']; // Pega o ID gerado pelo Banco

             final novaCamera = Cameras(
                id: novoId, nome: nomeCamera, anguloX: anguloX, anguloY: anguloY, zoom: zoom, obraId: widget.obra.id, renderUrl: imageUrl, estatisticas: stats,
             );

             setState(() {
                listaCameras.add(novaCamera);
                Info.listaCameras = listaCameras;
                _cameraSelecionada = novaCamera;
                _indiceSelecionado = 1;
                _angXController.clear(); _angYController.clear(); _zoomController.clear(); _nomeController.clear();
             });
             if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Câmera salva com sucesso!")));
          }
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Falha: $e"), backgroundColor: Colors.red));
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _recarregarDadosObra() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/obra/${widget.obra.id}"));
      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);
        setState(() {
          widget.obra.progresso = (dados['progresso'] as num).toDouble();
        });
      }
    } catch (e) {
      print("Erro ao recarregar dados da obra: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final larguraTela = MediaQuery.of(context).size.width;
    final isMobile = larguraTela < 570;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
        title: Text(widget.obra.nome),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        backgroundColor: Cores.azulMetro,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isMobile) IconButton(icon: const Icon(Icons.menu, color: Colors.white), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        ],
      ),
      
      // MENU MOBILE (DRAWER)
      drawer: isMobile 
          ? MenuLateral(
              isMobile: true,
              listaCameras: listaCameras,
              obraId: widget.obra.id,
              indiceSelecionado: _indiceSelecionado,
              cameraSelecionada: _cameraSelecionada,
              onSelecao: (index, camera) => setState(() {
                _indiceSelecionado = index;
                _cameraSelecionada = camera;
              }),
            )
          : null,
          
      body: Row(
        children: [
          // MENU DESKTOP (FIXO)
          if (!isMobile)
             Container(
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(2, 0))]),
              child: MenuLateral(
                isMobile: false,
                listaCameras: listaCameras,
                obraId: widget.obra.id,
                indiceSelecionado: _indiceSelecionado,
                cameraSelecionada: _cameraSelecionada,
                onSelecao: (index, camera) => setState(() {
                  _indiceSelecionado = index;
                  _cameraSelecionada = camera;
                }),
              ),
            ),

          // CONTEÚDO
          Expanded(
            child: _indiceSelecionado == 0
                ? VisaoGeral(obra: widget.obra)
                : _indiceSelecionado == 1 && _cameraSelecionada != null
                    ? CameraView(
                        camera: _cameraSelecionada!,
                        opacidadeOverlay: _opacidadeOverlay,
                        mostrarAnotacoesIA: _mostrarAnotacoesIA,
                        onOpacidadeChanged: (val) => setState(() => _opacidadeOverlay = val),
                        onMostrarIAChanged: (val) => setState(() => _mostrarAnotacoesIA = val),
                        onAdicionarFoto: _adicionarImagemReal,
                        onExcluirCamera: _excluirCameraAtual,
                      )
                    : CameraForm(
                        nomeController: _nomeController,
                        angXController: _angXController,
                        angYController: _angYController,
                        zoomController: _zoomController,
                        isProcessing: _isProcessing,
                        onSalvar: _salvarCamera,
                        onCancelar: () => setState(() => _indiceSelecionado = 0),
                      ),
          ),
        ],
      ),
    );
  }
}