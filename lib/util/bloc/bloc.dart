import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:obras_view/telas/obras_dashboard.dart';
import 'package:obras_view/util/cores.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'validators.dart';
import 'package:rxdart/rxdart.dart';

class Bloc with Validators{

  final _emailController = BehaviorSubject<String>();
  final _passwordController = BehaviorSubject<String>();

  Stream<String> get email => _emailController.stream.transform(validateEmail);
  Stream<String> get password => _passwordController.stream.transform(validatePassword);
  Stream<bool> get emailPasswordOk => CombineLatestStream.combine2(email, password, (e, p) => true);


  Function(String) get changeEmail => _emailController.sink.add;
  Function(String) get changePassword => _passwordController.sink.add;

  void dispose(){
    _emailController.close();
    _passwordController.close();
  }

  Future<void> submitForm(BuildContext context) async {
    final email = _emailController.value;
    final password = _passwordController.value;

    // Mostra um feedback visual de carregamento (opcional, mas bom)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Verificando credenciais...")),
    );

    // [NOVO] Chama o backend Python
    final loginSucesso = await _loginAPI(email, password);

    if (loginSucesso) {
      // SUCESSO: Remove o snackbar anterior e navega
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => ObrasDashboard()));
    } else {
      // ERRO
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Usuário e/ou senha inválidos",
            textAlign: TextAlign.center,
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Cores.azulMetro,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // [NOVO] Função que conecta no banco de dados via Python
  Future<bool> _loginAPI(String email, String password) async {
    final url = Uri.parse('http://127.0.0.1:8000/login');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "senha": password,
        }),
      );

      if (response.statusCode == 200) {
        return true; // Login autorizado pelo banco
      } else {
        return false; // Senha errada ou usuário não existe
      }
    } catch (e) {
      print("Erro de conexão: $e");
      return false;
    }
  }
}


final bloc = Bloc();