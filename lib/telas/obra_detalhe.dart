import 'dart:convert'; // Para jsonDecode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Importação do HTTP
import 'package:obras_view/util/cameras.dart';
import 'package:obras_view/util/components/visao_geral.dart';
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
  int _indiceSelecionado = 0;
  Cameras? _cameraSelecionada;
  List<Cameras> listaCameras = Info.listaCameras;

  final TextEditingController _angXController = TextEditingController();
  final TextEditingController _angYController = TextEditingController();
  final TextEditingController _zoomController = TextEditingController();

  bool _isProcessing = false;

  // URL DO SEU BACKEND (Ajuste se for rodar em emulador Android para 10.0.2.2)
  final String baseUrl = "http://127.0.0.1:8000"; 

  @override
  void dispose() {
    _angXController.dispose();
    _angYController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  Future<void> _salvarCamera() async {
    if (_angXController.text.isNotEmpty &&
        _angYController.text.isNotEmpty &&
        _zoomController.text.isNotEmpty) {
      
      setState(() => _isProcessing = true);

      final anguloX = double.tryParse(_angXController.text) ?? 0.0;
      final anguloY = double.tryParse(_angYController.text) ?? 0.0;
      final zoom = double.tryParse(_zoomController.text) ?? 10.0;
      final nomeCamera = "Câmera ${listaCameras.length + 1}";

      try {
        // --- REQUISIÇÃO AO BACKEND ---
        var uri = Uri.parse("$baseUrl/renderizar_camera");
        
        var request = http.MultipartRequest('POST', uri)
          ..fields['obra_id'] = widget.obra.id.toString()
          ..fields['azimuth'] = anguloX.toString()
          ..fields['elevation'] = anguloY.toString()
          ..fields['zoom'] = zoom.toString();

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final imageUrl = data['image_url']; // Recebe a URL gerada

          final novaCamera = Cameras(
            nome: nomeCamera,
            anguloX: anguloX,
            anguloY: anguloY,
            zoom: zoom,
            obraId: widget.obra.id,
            renderUrl: imageUrl, // Salva a URL
          );

          setState(() {
            listaCameras.add(novaCamera);
            _cameraSelecionada = novaCamera;
            _indiceSelecionado = 1;
            _angXController.clear();
            _angYController.clear();
            _zoomController.clear();
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Render gerado pelo servidor!")),
            );
          }
        } else {
          throw Exception("Erro no servidor: ${response.body}");
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Falha: $e"), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final camerasDaObra = listaCameras.where((c) => c.obraId == widget.obra.id).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.obra.nome),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
        backgroundColor: Cores.azulMetro,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Row(
        children: [
          // MENU LATERAL
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                )
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildMenuButton(
                  icon: Icons.dashboard_outlined,
                  label: "Visão Geral",
                  isSelected: _indiceSelecionado == 0,
                  onTap: () => setState(() {
                    _indiceSelecionado = 0;
                    _cameraSelecionada = null;
                  }),
                ),
                if (camerasDaObra.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Câmeras", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  ...camerasDaObra.map((camera) => _buildMenuButton(
                    icon: Icons.videocam_outlined,
                    label: camera.nome,
                    isSelected: _indiceSelecionado == 1 && _cameraSelecionada == camera,
                    onTap: () => setState(() {
                      _indiceSelecionado = 1;
                      _cameraSelecionada = camera;
                    }),
                  )),
                ],
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() {
                      _indiceSelecionado = 2;
                      _cameraSelecionada = null;
                    }),
                    icon: const Icon(Icons.add_a_photo, color: Colors.white),
                    label: const Text("Nova Câmera", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Cores.azulMetro,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // CONTEÚDO PRINCIPAL
          Expanded(
            child: _indiceSelecionado == 0
                ? VisaoGeral(obra: widget.obra)
                : _indiceSelecionado == 1 
                    ? _buildDetalheCameras() 
                    : _buildFormCameras(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? Cores.azulMetro.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected ? Border.all(color: Cores.azulMetro.withOpacity(0.3)) : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Cores.azulMetro : Colors.grey[600]),
        title: Text(label, style: TextStyle(color: isSelected ? Cores.azulMetro : Colors.grey[800], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildFormCameras() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24.0),
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Cores.azulMetro),
                    onPressed: () => setState(() => _indiceSelecionado = 0),
                  ),
                  Text("Adicionar Nova Câmera", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Cores.azulMetro)),
                ],
              ),
              const SizedBox(height: 30),
              TextField(controller: _angXController, keyboardType: TextInputType.number, enabled: !_isProcessing, decoration: InputDecoration(labelText: "Ângulo X (Azimute)", suffixText: "°", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.rotate_left))),
              const SizedBox(height: 20),
              TextField(controller: _angYController, keyboardType: TextInputType.number, enabled: !_isProcessing, decoration: InputDecoration(labelText: "Ângulo Y (Elevação)", suffixText: "°", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.rotate_90_degrees_ccw))),
              const SizedBox(height: 20),
              TextField(controller: _zoomController, keyboardType: TextInputType.number, enabled: !_isProcessing, decoration: InputDecoration(labelText: "Zoom ", suffixText: "x", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), prefixIcon: const Icon(Icons.straighten))),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _salvarCamera,
                  style: ElevatedButton.styleFrom(backgroundColor: Cores.azulMetro, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: _isProcessing 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text("Salvar e Renderizar", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetalheCameras() {
    if (_cameraSelecionada == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_cameraSelecionada!.nome, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Cores.azulMetro)),
          const SizedBox(height: 10),
          Row(
            children: [
              Chip(label: Text("Azimute: ${_cameraSelecionada!.anguloX}°")),
              const SizedBox(width: 10),
              Chip(label: Text("Elevação: ${_cameraSelecionada!.anguloY}°")),
              const SizedBox(width: 10),
              Chip(label: Text("Zoom: ${_cameraSelecionada!.zoom}x")),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))],
              ),
              child: _cameraSelecionada!.renderUrl != null
                  // MUDANÇA: Image.network em vez de Image.file
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _cameraSelecionada!.renderUrl!,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.broken_image, size: 50, color: Colors.redAccent), Text("Erro ao carregar imagem do servidor.")]));
                        },
                      ),
                    )
                  : const Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.image_not_supported_outlined, size: 60, color: Colors.grey), SizedBox(height: 10), Text("Nenhum render disponível.", style: TextStyle(color: Colors.grey))]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}