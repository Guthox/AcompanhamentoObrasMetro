// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../util/cores.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CadastroUsuarioTela extends StatefulWidget {
  
  static const String routeName = '/cadastro';

  const CadastroUsuarioTela({super.key});

  @override
  State<CadastroUsuarioTela> createState() => _CadastroUsuarioTelaState();
}

class _CadastroUsuarioTelaState extends State<CadastroUsuarioTela> {
  final _formKey = GlobalKey<FormState>();

  
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      
      final url = Uri.parse('http://127.0.0.1:8000/cadastro');

      try {
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "nome": _nomeController.text,
            "email": _emailController.text,
            "senha": _senhaController.text,
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuário cadastrado com sucesso!')),
          );
          Navigator.of(context).pop(); // Volta para login
        } else {
          // Exibe erro (ex: email já existe)
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Erro: Email já cadastrado.'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Erro de conexão: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final screenHeight = MediaQuery.of(context).size.height;
   
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, 
      statusBarIconBrightness: Brightness.light, 
    ));

    return Scaffold(
      
      extendBodyBehindAppBar: true,
      
      
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      
      
      body: Container(
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
                  
                  
                  child: Card(
                    elevation: 10,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 32.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            Image.asset(
                              'assets/metro-sp-logo.png', // Caminho da imagem
                              height: screenHeight * 0.15, // Altura: 15% da tela
                              fit: BoxFit.contain, // Ajuste para não distorcer
                            ),
                            
                            Text(
                              "Criar Conta",
                              style: TextStyle(
                                fontSize: 24, 
                                fontWeight: FontWeight.bold,
                                color: Cores.azulMetro
                              ),
                            ),
                            const SizedBox(height: 30),

                            
                            
                            TextFormField(
                              controller: _nomeController,
                              decoration: InputDecoration(
                                labelText: 'Nome Completo',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)
                                ),
                                prefixIcon: const Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor, digite seu nome';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),

                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'E-mail',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)
                                ),
                                prefixIcon: const Icon(Icons.email),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || !value.contains('@') || !value.contains('.')) {
                                  return 'Formato de e-mail inválido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16.0),

                            TextFormField(
                              controller: _senhaController,
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)
                                ),
                                prefixIcon: const Icon(Icons.lock),
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.length < 6) {
                                  return 'A senha deve ter pelo menos 6 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24.0),

                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Cores.azulMetro,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: const Text(
                                  'Cadastrar',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
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
}