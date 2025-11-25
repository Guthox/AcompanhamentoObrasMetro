import 'package:flutter/material.dart';
import 'package:obras_view/util/cores.dart';

class CameraForm extends StatelessWidget {
  final TextEditingController nomeController;
  final TextEditingController angXController;
  final TextEditingController angYController;
  final TextEditingController zoomController;
  final bool isProcessing;
  final VoidCallback onSalvar;
  final VoidCallback onCancelar;

  const CameraForm({
    super.key,
    required this.nomeController,
    required this.angXController,
    required this.angYController,
    required this.zoomController,
    required this.isProcessing,
    required this.onSalvar,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
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
                    onPressed: onCancelar,
                  ),
                  Text("Adicionar Câmera", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Cores.azulMetro)),
                ],
              ),
              const SizedBox(height: 30),
              _buildField(nomeController, "Nome da Câmera", Icons.camera_alt, false),
              const SizedBox(height: 20),
              _buildField(angXController, "Ângulo X (Azimute)", Icons.rotate_left, true, suffix: "°"),
              const SizedBox(height: 20),
              _buildField(angYController, "Ângulo Y (Elevação)", Icons.rotate_90_degrees_ccw, true, suffix: "°"),
              const SizedBox(height: 20),
              _buildField(zoomController, "Zoom", Icons.straighten, true, suffix: "x"),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isProcessing ? null : onSalvar,
                  style: ElevatedButton.styleFrom(backgroundColor: Cores.azulMetro, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: isProcessing
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Salvar", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, bool isNumber, {String? suffix}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      enabled: !isProcessing,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: Icon(icon),
      ),
    );
  }
}