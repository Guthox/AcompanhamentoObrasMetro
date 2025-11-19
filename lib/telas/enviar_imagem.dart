import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:obras_view/util/cores.dart';

class EnviarImagem extends StatefulWidget {
  @override
  _EnviarImagemState createState() => _EnviarImagemState();
}

class _EnviarImagemState extends State<EnviarImagem> {
  final ImagePicker _imgPicker = ImagePicker();

  List<Uint8List> _fotosSelecionadas = [];

  Future<void> _imagemDaGaleria() async {
    final List<XFile>? imagens = await _imgPicker.pickMultiImage();

    if (imagens != null) {
      for (var img in imagens) {
        final bytes = await img.readAsBytes(); // funciona no web e mobile
        _fotosSelecionadas.add(bytes);
      }
      setState(() {});
    }
  }

  Future<void> _tirarFoto() async {
    final XFile? foto = await _imgPicker.pickImage(source: ImageSource.camera);

    if (foto != null) {
      final bytes = await foto.readAsBytes(); 
      setState(() {
        _fotosSelecionadas.add(bytes);
      });
    }
  }

  void _enviarImagens() {
    if (_fotosSelecionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Nenhuma imagem selecionada", textAlign: TextAlign.center),
          duration: Duration(seconds: 3),
          backgroundColor: Cores.azulMetro,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // TODO: envio das imagens

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Imagens enviadas com sucesso", textAlign: TextAlign.center),
        duration: Duration(seconds: 3),
        backgroundColor: Cores.azulMetro,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    setState(() {
      _fotosSelecionadas.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Enviar fotos")),
      body: Column(
        children: [
          Expanded(
            child: _fotosSelecionadas.isEmpty
                ? Center(child: Text("Nenhuma foto selecionada."))
                : GridView.builder(
                    padding: EdgeInsets.all(8.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: _fotosSelecionadas.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.memory(
                              _fotosSelecionadas[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _fotosSelecionadas.removeAt(index);
                                });
                              },
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black,
                                child: Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          )
                        ],
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                    onPressed: _imagemDaGaleria,
                    icon: Icon(Icons.photo_library),
                    label: Text("Galeria")),
                ElevatedButton.icon(
                    onPressed: _tirarFoto,
                    icon: Icon(Icons.camera_alt),
                    label: Text("Câmera")),
                ElevatedButton.icon(
                    onPressed: _enviarImagens,
                    icon: Icon(Icons.cloud_upload),
                    label: Text("Enviar Imagens"))
              ],
            ),
          )
        ],
      ),
    );
  }
}
