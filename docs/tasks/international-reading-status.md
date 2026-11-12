# Aleph: resultado desta sessão — 16/10/2026

## O que foi corrigido

Branch local: `fix/international-reading-20261016`. Alterações prontas para
revisão na pasta do projeto; nenhum envio às lojas foi feito.

- Instalações novas escolhem o primeiro idioma do aparelho suportado pelo app,
  junto com a Bíblia correspondente. Uma preferência já salva continua valendo.
- Códigos como `pt-BR`, `es_MX` e `zh-Hant-TW` são reconhecidos pelo idioma
  principal, em vez de virarem inglês.
- Uma edição antiga ou inválida salva, como `ACF`, é corrigida para a edição
  disponível no idioma salvo. Uma escolha manual válida é preservada.
- A falta de tradução de um capítulo deixou de carregar inglês e mudar a
  preferência de todos os capítulos para `KJV`. O leitor mostra a mensagem
  localizada de tradução indisponível que já existia.
- O nome da língua na mensagem de voz ausente passou a usar a tradução da
  interface; não insere mais "Modern Israeli" ou "Modern Greek" em inglês.

Arquivos de implementação alterados nesta sessão:

- `lib/features/settings/settings_provider.dart`
- `lib/features/reading/reading_provider.dart`
- `lib/features/audio/widgets/recitation_bar.dart`
- `test/settings_provider_test.dart`
- `test/reading_translation_fallback_test.dart`

A mudança anterior em `lib/main.dart` foi preservada. O banco não foi
regenerado ou alterado nesta sessão; foi inspecionado em modo somente leitura.

## Verificações

- Testes direcionados: 22 aprovados.
- `flutter test --reporter expanded`: 284 aprovados, 2 ignorados, nenhuma falha.
- `bash scripts/validate_release.sh`: aprovado, incluindo os 28 testes Python
  do enriquecimento lexical. Banco com 66 livros, 31.152 versículos,
  607.217 palavras e oito traduções habilitadas.
- `git diff --check`: aprovado.
- `flutter analyze`: encerrou com código 1 por um único aviso informativo:
  `depend_on_referenced_packages` em `lib/main.dart:6`. A alteração anterior
  desse arquivo importa `sqflite_common_ffi`, que está em `dev_dependencies`.
  O aviso fica registrado; não foi tratado como uma análise sem problemas.
- Não foram testados aparelhos Android/iPhone nem produzidos builds de loja.

## O que ainda precisa ser feito

O áudio continua dependendo das vozes do sistema. Não há vozes israelense e
grega embutidas nesta entrega. O trabalho está detalhado em
[embedded-voices.md](embedded-voices.md).

O banco já contém Bíblias e significados curtos nos idiomas suportados.
Definições longas e rótulos gramaticais ainda têm inglês. A tradução integral
é o trabalho de maior volume: cerca de 3,9 milhões de caracteres de origem
para sete idiomas, antes de deduplicação. A tarefa está detalhada em
[international-lexicon.md](international-lexicon.md).

Os dois arquivos podem ser copiados integralmente para outro agente. Eles
incluem arquivos envolvidos, limites, preservação de licenças, testes e
critérios para distinguir uma implementação real de infraestrutura incompleta.
