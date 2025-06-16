import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(ParImparApp());

class ParImparApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Par ou Ímpar',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: CadastroPage(),
    );
  }
}

class CadastroPage extends StatefulWidget {
  @override
  _CadastroPageState createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _usernameController = TextEditingController();

  void _cadastrarUsuario() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return;

    final response = await http.post(
      Uri.parse('https://par-impar.glitch.me/novo'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username}),
    );	

    if (response.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ApostaPage(username: username),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao cadastrar jogador")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cadastro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _usernameController, decoration: InputDecoration(labelText: 'Seu nome')),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _cadastrarUsuario, child: Text("Entrar no Jogo"))
          ],
        ),
      ),
    );
  }
}

class ApostaPage extends StatefulWidget {
  final String username;
  ApostaPage({required this.username});

  @override
  _ApostaPageState createState() => _ApostaPageState();
}

class _ApostaPageState extends State<ApostaPage> {
  int _valor = 100;
  int _numero = 1;
  int _parimpar = 2;

  void _apostar() async {
    final response = await http.post(
      Uri.parse('https://par-impar.glitch.me/aposta'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': widget.username,
        'valor': _valor,
        'parimpar': _parimpar,
        'numero': _numero
      }),
    );

    if (response.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ListaJogadoresPage(username: widget.username),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao apostar")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Aposta')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column( 
          children: [
            DropdownButton<int>(
              value: _numero,
              onChanged: (val) => setState(() => _numero = val!),
              items: [1, 2, 3, 4, 5].map((n) => DropdownMenuItem(value: n, child: Text('Número: $n'))).toList(),
            ),
            DropdownButton<int>(
              value: _parimpar,
              onChanged: (val) => setState(() => _parimpar = val!),
              items: [
                DropdownMenuItem(value: 2, child: Text('Par')),
                DropdownMenuItem(value: 1, child: Text('Ímpar')),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: _apostar, child: Text('Apostar')),
          ],
        ),
      ),
    );
  }
}

class ListaJogadoresPage extends StatelessWidget {
  final String username;
  ListaJogadoresPage({required this.username});

  Future<List<dynamic>> _buscarJogadores() async {
    final response = await http.get(Uri.parse('https://par-impar.glitch.me/jogadores'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['jogadores'];
    } else {
      return [];
    }
  }

  void _jogarContra(BuildContext context, String oponente) async {
    final response = await http.get(Uri.parse('https://par-impar.glitch.me/jogar/$username/$oponente'));

    if (response.statusCode == 200) {
      final resultado = jsonDecode(response.body);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultadoPage(resultado: resultado, username: username),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao jogar")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Escolha oponente')),
      body: FutureBuilder<List<dynamic>>(
        future: _buscarJogadores(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final jogadores = snapshot.data!;
          return ListView.builder(
            itemCount: jogadores.length,
            itemBuilder: (context, index) {
              final j = jogadores[index];
              if (j['username'] == username) return Container();
              return ListTile(
                title: Text(j['username']),
                subtitle: Text("Pontos: ${j['pontos']}"),
                trailing: Icon(Icons.play_arrow),
                onTap: () => _jogarContra(context, j['username']),
              );
            },
          );
        },
      ),
    );
  }
}

class ResultadoPage extends StatelessWidget {
  final Map<String, dynamic> resultado;
  final String username;

  ResultadoPage({required this.resultado, required this.username});

  @override
  Widget build(BuildContext context) {
    final vencedor = resultado['vencedor']['username'];
    final msg = vencedor == username ? "Você venceu!" : "Você perdeu!";
    return Scaffold(
      appBar: AppBar(title: Text("Resultado")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(msg, style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => ApostaPage(username: username)),
                );
              },
              child: Text("Jogar novamente"),
            ),
          ],
        ),
      ),
    );
  }
}