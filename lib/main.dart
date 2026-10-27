import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ComentariosApp());
}

class ComentariosApp extends StatelessWidget {
  const ComentariosApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Comentários em Tempo Real', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    home: const PublicacoesPage());
}


class PublicacoesPage extends StatelessWidget {
  const PublicacoesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final publicacoes =
        FirebaseFirestore.instance.collection('publicacoes');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicações'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: publicacoes
            .orderBy('criadoEm', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Erro ao carregar publicações.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text('Nenhuma publicação encontrada.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final texto = (
                data['texto'] ??
                data['conteudo'] ??
                data['mensagem'] ??
                'Publicação'
              ).toString();

              final nome = (
                data['nome'] ??
                data['autor'] ??
                'Usuário'
              ).toString();

              return Card(
                child: ListTile(
                  title: Text(texto),
                  subtitle: Text('Por: $nome'),
                  trailing: IconButton(
                    icon: const Icon(Icons.comment_outlined),
                    tooltip: 'Comentários',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ComentariosPage(
                            publicacaoId: doc.id,
                            publicacao: texto,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}



class ComentariosPage extends StatefulWidget {
  final String publicacaoId, publicacao;
  const ComentariosPage({super.key, required this.publicacaoId, required this.publicacao});
  @override
  State<ComentariosPage> createState() => _ComentariosPageState();
}
class _ComentariosPageState extends State<ComentariosPage> {
  final _texto = TextEditingController();
  bool _enviando = false;
  final _auth = FirebaseAuth.instance;
  CollectionReference<Map<String, dynamic>> get _comentarios =>
    FirebaseFirestore.instance.collection('publicacoes').doc(widget.publicacaoId).collection('comentarios');
  @override
  void dispose() { _texto.dispose(); super.dispose(); }
  void _aviso(String s) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s))); }
  Future<void> _enviar() async {
    final user = _auth.currentUser; final texto = _texto.text.trim();
    if (user == null) { _aviso('Faça login para comentar.'); return; }
    if (texto.isEmpty) { _aviso('Digite um comentário.'); return; }
    setState(() => _enviando = true);
    try {
      await _comentarios.add({'texto': texto, 'nome': user.displayName ?? user.email ?? 'Usuário',
        'usuarioId': user.uid, 'publicacaoId': widget.publicacaoId,
        'criadoEm': FieldValue.serverTimestamp()});
      _texto.clear();
    } catch (_) { _aviso('Falha ao enviar. Confira as regras do Firestore.'); }
    finally { if (mounted) setState(() => _enviando = false); }
  }
  Future<void> _excluir(DocumentSnapshot<Map<String, dynamic>> doc) async {
    if (_auth.currentUser?.uid != doc.data()?['usuarioId']) { _aviso('Você só pode excluir seus comentários.'); return; }
    try { await doc.reference.delete(); } catch (_) { _aviso('Não foi possível excluir.'); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Comentários')),
    body: Column(children: [
      Container(width: double.infinity, padding: const EdgeInsets.all(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest, child: Text(widget.publicacao)),
      Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _comentarios.orderBy('criadoEm').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Erro ao carregar comentários.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Seja o primeiro a comentar!'));
          return ListView(children: docs.map((doc) {
            final data = doc.data(); final meu = _auth.currentUser?.uid == data['usuarioId'];
            return Card(child: ListTile(title: Text((data['nome'] ?? 'Usuário').toString()),
              subtitle: Text((data['texto'] ?? '').toString()),
              trailing: meu ? IconButton(icon: const Icon(Icons.delete_outline),
                onPressed: () => _excluir(doc)) : null));
          }).toList());
        })),
      SafeArea(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        Expanded(child: TextField(controller: _texto, minLines: 1, maxLines: 4,
          decoration: const InputDecoration(hintText: 'Escreva um comentário...', border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        IconButton.filled(onPressed: _enviando ? null : _enviar,
          icon: _enviando ? const SizedBox(width: 18,height: 18,child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send))
      ])))
    ]));
}
