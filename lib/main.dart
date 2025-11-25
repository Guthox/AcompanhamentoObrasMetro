import 'package:flutter/material.dart';
import 'package:obras_view/telas/login.dart';
import 'package:obras_view/telas/cadastro_usuario.dart';

void main(){
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false, // Mudar para false para remover banner debug
    initialRoute: '/login',

    //Mapa de rotas da aplicação
    routes: {
      '/login': (context) => Login(),
      CadastroUsuarioTela.routeName: (context) => const CadastroUsuarioTela(),
    }
  ));
}