# Comentários em Tempo Real

Este ZIP contém uma implementação-base em Flutter com Cloud Firestore e Firebase Authentication: lista publicações da coleção `publicacoes`, abre a discussão de cada publicação, envia comentários em tempo real e permite excluir apenas os comentários do próprio usuário.

## Configuração
1. Abra esta pasta no VS Code.
2. No terminal execute:
   ```powershell
   flutter pub get
   dart pub global activate flutterfire_cli
   npm install -g firebase-tools
   firebase login
   dart pub global run flutterfire_cli:flutterfire configure
   ```
3. Selecione seu projeto Firebase e marque `web` para executar no Chrome. Será gerado `lib/firebase_options.dart`.
4. Ative Firebase Authentication e Cloud Firestore no console.
5. Revise/adapte `firestore.rules` antes de publicar. As regras de publicação incluídas são amplas para exemplo; preserve as regras seguras do app original.
6. Execute `flutter run -d chrome`.

## Importante
A atividade pede continuar o aplicativo feito na aula e manter login, perfil e publicações. Como o código original da aula não foi enviado, este pacote é uma base independente e espera publicações na coleção `publicacoes`, com texto em `texto`, `conteudo` ou `mensagem`. Talvez seja necessário adaptar nomes de coleções/campos ao seu projeto original.

Comentários ficam em `publicacoes/{publicacaoId}/comentarios/{comentarioId}` e armazenam `texto`, `nome`, `usuarioId`, `publicacaoId` e `criadoEm`. `StreamBuilder` com `snapshots()` atualiza a tela automaticamente.
