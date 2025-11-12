import 'package:flutter/material.dart';
import '../util/cores.dart';

class CadastroUsuarioTela extends StatefulWidget {

  static const String routeName = '\cadastro';

  const CadastroUsuarioTela({Key? key}) : super (key: key);

  @override
  State<CadastroUsuarioTela> createState() => _CadastroUsuarioTelaState();
}

class _CadastroUsuarioTelaState extends State<CadastroUsuarioTela>{

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  @override
  void dispose(){
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _submitForm(){

    if(_formKey.currentState?.validate() ?? false){
      String nome = _nomeController.text;
      String email = _emailController.text;
      String senha = _senhaController.text;

      print('Simulando cadastro: Nome: $nome, Email: $email');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro enviado (simulação)!')),
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Usando a cor do seu projeto!
        backgroundColor: Cores.azulMetro, 
        title: const Text('Criar Nova Conta'),
        // Adiciona um ícone de "voltar" automaticamente
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView( 
            children: [
              // Campo de Texto para o Nome
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, digite seu nome';
                  }
                  return null; 
                },
              ),
              const SizedBox(height: 16.0), // Espaçamento

              // Campo de Texto para o Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !value.contains('@') || !value.contains('.')) {
                    return 'Formato de e-mail inválido';
                  }
                  return null; 
                },
              ),
              const SizedBox(height: 16.0), // Espaçamento

              // Campo de Texto para a Senha
              TextFormField(
                controller: _senhaController,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true, // Esconde o texto da senha
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'A senha deve ter pelo menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0), 

              // Botão de Cadastro
              ElevatedButton(
                onPressed: _submitForm, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: Cores.azulMetro, // Use sua cor
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text(
                  'Cadastrar',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}