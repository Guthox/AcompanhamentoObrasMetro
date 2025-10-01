import 'package:email_validator/email_validator.dart';
import 'dart:async';

mixin Validators {

  final validateEmail = StreamTransformer<String, String>.fromHandlers(
    handleData: (email, sink){
      if (EmailValidator.validate(email)){
        sink.add(email);
      }
      else{
        sink.addError("Email inválido");
      }
    }
  );

  final validatePassword = StreamTransformer<String, String>.fromHandlers(
    handleData: (password, sink){
      if (password.length > 3){
        sink.add(password);
      }
      else{
        sink.addError("Senha deve ter no mínimo 4 caracteres.");
      }
    }
  );


}