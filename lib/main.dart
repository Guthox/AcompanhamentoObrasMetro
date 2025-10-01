import 'package:flutter/material.dart';
import 'package:obras_view/telas/login.dart';

void main(){
  runApp(MaterialApp(
    debugShowCheckedModeBanner: true, // Mudar para false para remover banner debug
    home: Login(),
  ));
}