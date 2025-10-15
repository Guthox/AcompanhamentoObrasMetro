import 'dart:io';
import 'package:image_picker/image_picker.dart';

// TODO
// Apenas para testar o storage
class Storage {

  static final List<File> _fotosSalvas = [];

  static void addFotos(List<File> fotos){
    for (int i = 0; i < fotos.length; i++){
      _fotosSalvas.add(fotos[i]);
    }
  }

  static void clear(){
    _fotosSalvas.clear();
  }

  static List<File> getFotos(){
    return _fotosSalvas;
  }
}