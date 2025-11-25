import 'package:obras_view/util/cameras.dart';
import 'package:obras_view/util/imagens.dart';
import 'package:obras_view/util/obras.dart';

class Info {

  static List<Obras> listaObras = [];
  static List<Cameras> listaCameras = [];
  static List<Imagens> listaImagens = [];

  static addObra(Obras obra){
    listaObras.add(obra);
  }

  static addCamera(Cameras camera){
    listaCameras.add(camera);
  }

  static addImagem(Imagens imagem){
    listaImagens.add(imagem);
  }
}