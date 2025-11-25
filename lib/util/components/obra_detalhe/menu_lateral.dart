import 'package:flutter/material.dart';
import 'package:obras_view/util/cameras.dart';
import 'package:obras_view/util/cores.dart';

class MenuLateral extends StatelessWidget {
  final List<Cameras> listaCameras;
  final int obraId;
  final int indiceSelecionado;
  final Cameras? cameraSelecionada;
  final Function(int index, Cameras? camera) onSelecao;
  final bool isMobile;

  const MenuLateral({
    super.key,
    required this.listaCameras,
    required this.obraId,
    required this.indiceSelecionado,
    required this.cameraSelecionada,
    required this.onSelecao,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final camerasDaObra = listaCameras.where((c) => c.obraId == obraId).toList();

    void fecharDrawerSeMobile() {
      if (isMobile) Navigator.pop(context);
    }

    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildMenuButton(
            icon: Icons.dashboard_outlined,
            label: "Visão Geral",
            isSelected: indiceSelecionado == 0,
            onTap: () {
              onSelecao(0, null);
              fecharDrawerSeMobile();
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  if (camerasDaObra.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Câmeras", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    ...camerasDaObra.map(
                      (camera) => _buildMenuButton(
                        icon: Icons.camera_alt_outlined,
                        label: camera.nome,
                        isSelected: indiceSelecionado == 1 && cameraSelecionada == camera,
                        onTap: () {
                          onSelecao(1, camera);
                          fecharDrawerSeMobile();
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                onSelecao(2, null);
                fecharDrawerSeMobile();
              },
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
    );
  }

  Widget _buildMenuButton({required IconData icon, required String label, required bool isSelected, required VoidCallback onTap}) {
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
}