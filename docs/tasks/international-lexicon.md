# Tarefa para outro agente: conteúdo do Aleph no idioma do leitor

Copie este arquivo inteiro como instrução para o agente responsável.

## Entrega desejada

Complete a tradução offline dos significados, definições e explicações gramaticais
do Aleph para português brasileiro, espanhol, alemão, francês, russo, chinês
simplificado e coreano. Inglês continua disponível como oitavo idioma. O leitor
deve conseguir tocar numa palavra e compreender o conteúdo sem saber inglês.

Repositório: `/home/gustvmar/Documents/Coding/Aleph`.
GitHub: https://github.com/cYoren/Aleph.
Leia `AGENTS.md`, `README.md`, `CONTRIBUTING.md` e `ROADMAP.md` antes de trabalhar.
Use branch própria e preserve trabalho existente. `lib/main.dart` já continha
uma mudança para banco de dados no Linux; não a reverta.

## Diagnóstico confirmado em 16/10/2026

Não comece retraduzindo a Bíblia ou todos os menus: já existem traduções.

- O banco local tem oito edições habilitadas, com 100% de cobertura declarada:
  `KJV` (identificador legado; o registro atual é Berean Standard Bible/BSB),
  `ALMEIDA`, `LUTHER1912`, `OSTERVALD`, `VALERA1909`, `SYNODAL`, `CUVS` e `KOREAN`.
  `KOUGO`, em japonês, está incompleta e desabilitada; não a habilite nesta tarefa.
- `lib/l10n/app_*.arb` e os arquivos gerados já cobrem oito idiomas de interface.
  O inventário de strings idênticas ao inglês aponta também palavras corretas
  compartilhadas, como "final", "Tanakh" e "Torah"; não trate isso como tradução
  ausente automaticamente.
- `data/gloss_translations/{pt,es,de,fr,ru,zh,ko}.json` já contém 13.281
  significados curtos por idioma, importados em `lexicon_gloss_i18n`.
- `BibleDAO(glossLanguage: ...)`, em
  `lib/data/database/daos/bible_dao.dart`, já localiza o campo `gloss` das consultas
  lexicais e do índice de busca. `lib/providers/database_provider.dart` acompanha
  o idioma das configurações e invalida as consultas ao trocá-lo.
- A lacuna principal: `lexicon.definition` e `lexicon.extended_definition`
  continuam em inglês e são exibidos por
  `lib/shared/widgets/definition_sheet.dart`.
- O banco examinado tem 13.666 linhas lexicais, 13.281 IDs Strong's distintos,
  13.666 definições básicas e 13.617 definições estendidas não nulas. São cerca
  de 3,9 milhões de caracteres nos dois campos de origem, antes de traduzir
  para sete idiomas. Planeje lotes retomáveis e deduplicação verificável.
- `lib/shared/utils/morphology_decoder.dart` produz rótulos em inglês, usados
  na ficha da palavra e no exercício via `lib/shared/utils/parsing_quiz.dart`.
  Essas strings não aparecem adequadamente no inventário simples de widgets.

## Correções já preparadas nesta sessão

A branch `fix/international-reading-20261016` reconhece códigos como `pt-BR`,
usa o primeiro idioma suportado do aparelho em instalações novas, corrige uma
edição inválida pelo idioma salvo e remove a troca automática para inglês
quando falta tradução de um capítulo. O carregador do capítulo passou a se
chamar `loadChapterTranslations`; não restaure a persistência automática de KJV.
O nome da língua na mensagem de voz ausente também usa a localização.

Não confunda essas correções com tradução integral de dicionários: essa parte
continua pendente e é o objetivo desta tarefa.

## Trabalho necessário

1. Exporte as definições reais do banco gerado, com identidade estável de entrada
   e hash do texto de origem. `lemma` é a chave primária atual; Strong's sozinho
   não identifica todas as linhas, pois há IDs repetidos. Preserve homônimos e
   variantes. Não perca os zeros e sufixos de IDs como `H0430` e `H0871A`.
2. Produza caches de tradução versionáveis por idioma, separados dos originais,
   com origem, licença, método, revisão e hash. Sugestão de diretório novo:
   `data/lexicon_translations/`. Ele ainda não existe nem é lido pelo app.
   Deduplicate apenas textos comprovadamente idênticos e restaure o vínculo
   com cada entrada. Lotes devem poder continuar sem pagar novamente pelos
   resultados já salvos. Não faça uma geração monolítica sem checkpoints.
3. Preserve texto hebraico/grego, referências bíblicas, Strong's, abreviações
   acadêmicas e distinções de sentido. Não transforme um glossário curto numa
   suposta tradução da definição completa nem invente explicações ausentes.
4. A tradução em massa é a parte de maior consumo. Antes de fazer chamadas
   pagas, apresente estimativa baseada na exportação real, modelo/provedor,
   deduplicação e tamanho de saída; confirme a forma de acesso e o orçamento
   com Gus. Não leia ou revele credenciais. Não acrescente tradução online ao app.
5. Integre os caches no pipeline `scripts/build_full_bible_db.py`, consultando
   o padrão atual de `scripts/apply_gloss_translations.py`. Use uma tabela
   separada de traduções completas e consultas locais, sem sobrescrever os
   originais. O banco `assets/bible.db` é gerado e não deve ser versionado.
6. Faça `BibleDAO` e `LexiconEntry` entregarem os campos no idioma escolhido
   em todas as consultas relevantes: entrada única, lote, prévia, leitura,
   vocabulário e estudo de palavra. Preserve idiomas de origem, atribuições
   Strong's/BDB/Abbott-Smith e proveniência da tradução.
7. Traduza os termos gramaticais em todos os oito ARBs; use as localizações
   geradas na ficha e no exercício. Não substitua códigos do banco. Garanta
   que respostas e alternativas do exercício usem a mesma localização e não
   fiquem duplicadas por traduções ambíguas.
8. Faça uma auditoria complementar de dados pedagógicos e telas que ainda
   mostrem inglês. `python3 scripts/find_untranslated.py` examina ARBs e alguns
   widgets; não comprova a tradução do conteúdo do banco ou dos decodificadores.
   Registre os casos reais e traduza-os, sem modificar nomes próprios corretos.
9. Amplie `scripts/validate_release.sh` para verificar cobertura de cada idioma
   e de cada campo. Contar apenas idiomas presentes não detecta um idioma com
   meia dúzia de linhas. Verifique chaves ausentes, strings vazias, placeholders,
   hashes desatualizados e tabelas ausentes. Declare qualquer lacuna, sem
   tratá-la como conteúdo traduzido.
10. Regenere o banco pelo comando documentado e aumente
    `kBundledDatabaseVersion` em `lib/data/database/database_mobile.dart` quando
    o novo conteúdo estiver pronto, para instalações antigas receberem a
    atualização. Preserve o banco separado com o progresso do usuário.
11. Atualize documentação e atribuições. Não remova os textos acadêmicos em
    inglês: mantenha os originais acessíveis e identifique idioma e origem
    quando usados como alternativa por ausência de tradução.

## Critérios de aceite

- Em cada um dos sete idiomas, tocar em palavras de Gênesis 1 e João 1 mostra
  significado, definição longa e gramática no idioma escolhido, sem internet.
- Mudar idioma atualiza ficha, prévia, vocabulário, busca e exercício; uma
  instalação com banco antigo recebe os novos textos sem perder progresso.
- Testes usam dados com originais e traduções deliberadamente diferentes,
  verificando idioma correto, lote, ausência de tradução e troca de idioma.
- Testar identidade de entradas com o mesmo Strong's e lemas diferentes,
  preservação de caracteres, referências e invalidação por mudança da origem.
- Relatório de cobertura real por idioma e campo; amostra revisada de hebraico
  e grego, incluindo termos polissêmicos e gramática. Distinguir tradução
  automática de revisão humana. Não afirmar que conteúdo foi revisado sem revisão.
- Executar `python3 scripts/find_untranslated.py`, `./scripts/validate_release.sh`,
  `flutter analyze` e `flutter test`. Registrar o comando de geração do banco e
  os resultados de cobertura e testes.
- Entregar mudanças revisáveis e informar custo real, tamanho adicional do
  banco, proveniência e limitações. Não publicar nas lojas nesta tarefa.

## Organização sugerida

Primeiro entregar exportação, esquema, consultas, localização gramatical e testes.
Depois executar os lotes de tradução com o orçamento aprovado e revisão de
amostras. Só declarar concluído quando os dados completos estiverem incorporados
e validados; infraestrutura sem traduções não satisfaz esta tarefa.
