import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obras_view/util/cores.dart';
import '../util/bloc/bloc.dart';
import 'package:obras_view/telas/cadastro_usuario.dart';

class Login extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    // Deixa a barra de status combinando com o tema
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Cores.azulMetro,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      body: Container(
        // ===== FUNDO GRADIENTE =====
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Cores.azulMetro,
              Cores.azulMetro.withOpacity(0.8),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                double maxWidth =
                    constraints.maxWidth > 600 ? 400 : double.infinity;

                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  // ===== CARTÃO BRANCO =====
                  child: Card(
                    elevation: 10,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ===== LOGO =====
                          Image.asset(
                            'assets/metro-sp-logo.png',
                            height: screenHeight * 0.20,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 32),

                          // ===== CAMPOS =====
                          _emailField(),
                          const SizedBox(height: 20),
                          _senhaField(),
                          const SizedBox(height: 30),

                          // ===== BOTÃO =====
                          SizedBox(
                            width: double.infinity,
                            child: _submitButton(),
                          ),

                          const SizedBox(height: 16.0),

                          TextButton(
                            onPressed: (){
                              Navigator.of(context).pushNamed(CadastroUsuarioTela.routeName);
                            },
                            child: Text(
                              'Cadastre-se',
                              style: TextStyle(color: Cores.azulMetro.withOpacity(0.9)),
                            )
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailField() {
    return StreamBuilder(
      stream: bloc.email,
      builder: (context, AsyncSnapshot<String> snapshot) {
        return TextField(
          onChanged: bloc.changeEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: "seu@email.com",
            labelText: "Email",
            labelStyle: const TextStyle(color: Colors.black87),
            errorText: snapshot.hasError ? snapshot.error.toString() : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Widget _senhaField() {
    return StreamBuilder(
      stream: bloc.password,
      builder: (context, AsyncSnapshot<String> snapshot) {
        return TextField(
          onChanged: bloc.changePassword,
          obscureText: true,
          decoration: InputDecoration(
            hintText: "Senha",
            labelText: "Senha",
            labelStyle: const TextStyle(color: Colors.black87),
            errorText: snapshot.hasError ? snapshot.error.toString() : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Widget _submitButton() {
    return StreamBuilder(
      stream: bloc.emailPasswordOk,
      builder: (context, AsyncSnapshot<bool> snapshot) {
        return ElevatedButton(
          onPressed: snapshot.hasData ? () => bloc.submitForm(context) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Cores.azulMetro,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: const Text(
            "Login",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }
}
