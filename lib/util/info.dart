import 'package:obras_view/util/cameras.dart';
import 'package:obras_view/util/obras.dart';

class Info {

  static List<Obras> listaObras = [];
  static List<Cameras> listaCameras = [];

  static addObra(Obras obra){
    listaObras.add(obra);
  }

  static addCamera(Cameras camera){
    listaCameras.add(camera);
  }

}