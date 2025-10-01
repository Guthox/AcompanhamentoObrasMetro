import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

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

  void submitForm(BuildContext context){
      final email = _emailController.value;
      final password = _passwordController.value;
      if (_verificaCadastro(email, password) == false){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Usuário e/ou senha inválidos", textAlign: TextAlign.center,),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      else{
        // MOVER PARA PROXIMA TELA
      }
  }

  // TODO fazer verificacao real de login
  bool _verificaCadastro(email, senha){
    if (senha == "1234"){
      return true;
    }
    return false;
  }

}

final bloc = Bloc();
