import 'package:flutter/material.dart';
import '../util/bloc/bloc.dart';

// TODO:
// Colocar cores do metro
// Colocar logo do metro

class Login extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("Login")),
      ),
      body: Container(
      margin: EdgeInsets.all(20.0),
      child: Column(
        children: [
          _emailField(),
          _senhaField(),
          Container(
            margin: EdgeInsets.only(top: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: _submitButton()
                )
              ],
            ),
          )
          ],
        ),
      ),
    );
  }

  Widget _emailField(){
    return StreamBuilder(
      stream: bloc.email,
      builder: ((context, AsyncSnapshot<String> snapshot){
        return TextField(
          onChanged: bloc.changeEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: "seu@email.com",
            labelText: "Email",
            errorText: snapshot.hasError ? snapshot.error.toString() : null
          ),
        );
      })
    );
  }

  Widget _senhaField(){
    return StreamBuilder(
      stream: bloc.password,
      builder: (context, AsyncSnapshot<String> snapshot){
        return TextField(
          onChanged: bloc.changePassword,
          obscureText: true,
          decoration: InputDecoration(
            hintText: "Senha",
            labelText: "Senha",
            errorText: snapshot.hasError ? snapshot.error.toString() : null
          ),
        );
      }
    );
  }

  Widget _submitButton(){
    return StreamBuilder(
      stream: bloc.emailPasswordOk,
      builder: (context, AsyncSnapshot<bool> snapshot){
        return ElevatedButton(
          onPressed: snapshot.hasData ? () => bloc.submitForm(context) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: Text("Login"), 
        );
      }
    );
  }
  
}