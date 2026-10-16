# Revisão antes do push

Branch: `feat/embedded-voices-lexicon-i18n`. Revisão do trabalho terceirizado
e correções adicionais; esta entrega não é uma publicação nas lojas.

## Correções feitas na revisão

- O pacote Flutter original continha o modelo, mas omitia todas as subpastas
  de `espeak-ng-data`. Foram declaradas as pastas necessárias no `pubspec.yaml`.
  O novo teste compara os arquivos reais da voz com o manifesto Flutter.
  No build revisado, todos os 359 arquivos estão presentes.
- A provisão agora verifica os arquivos essenciais e atualiza o carimbo da
  voz para a versão 2, corrigindo instalações que copiaram dados incompletos.
- Cancelamento durante síntese ou carregamento de áudio impede fala tardia.
  Comandos nativos de áudio são serializados; erros liberam a espera do leitor.
- Preparações simultâneas compartilham a mesma carga do modelo. O descarte
  invalida operações antigas e permite liberar o modelo nativo antes de
  encerrar seu isolate, com um limite para processos que não terminem.
- Uma palavra isolada interrompe a leitura anterior. Parar durante a preparação
  de capítulo ou palavra impede configuração e reprodução posteriores.
- Os quatro workflows de compilação do GitHub e o script de capturas preparam
  os modelos verificados antes de compilar. Nenhum workflow foi acionado aqui.
- A validação estrita confere os sete idiomas, mesmo se um idioma inteiro ou
  toda a tabela estiver sem traduções. Hash ausente ou vencido falha a
  integridade; campos ainda não traduzidos são registrados como lacunas.
- Respostas parciais do tradutor não contam como lotes completos. Falhas de
  autorização ou esgotamento de tentativas retornam erro ao processo.
- Documentação foi corrigida para distinguir implementação, validação em
  aparelhos e liberação para distribuição. A ausência de um modelo hebraico
  validado não demonstra que nenhum modelo adequado exista no mundo.
- A amostra de João 1:1 agora usa o texto grego original do banco, submetido à
  mesma preparação de texto do aplicativo, em vez de uma tradução moderna.

## Verificações concluídas

- `flutter analyze --no-pub`: nenhum problema.
- `flutter test --no-pub --reporter expanded`: 303 aprovados, 2 ignorados.
- `bash scripts/validate_release.sh`: aprovado; 28 testes de enriquecimento e
  13 testes do pipeline de traduções aprovados. Banco com oito Bíblias
  habilitadas. A validação registra explicitamente que as definições longas
  traduzidas ainda não foram geradas.
- `python3 scripts/find_untranslated.py`: nenhum valor ARB pendente; o
  inventário continua apontando 21 possíveis literais Dart, incluindo falsos
  positivos. Isso não comprova a tradução de todo conteúdo do banco.
- `python3 scripts/fetch_embedded_voices.py --verify`: hash do arquivo grego
  confirmado; modelo hebraico não comercial continua excluído.
- `flutter build linux --debug --no-pub`: aprovado.
- O probe Dart foi executado com os arquivos extraídos do aplicativo compilado,
  não com a pasta original de downloads. Gerou quatro WAVs de 16 kHz com
  energia de áudio não nula em `/tmp/aleph-review-samples/`. João 1:1 normal:
  4,12 s; lento: 6,91 s. O motor emitiu aviso sobre um fonema U+0327 ausente
  no vocabulário. Pronúncia e adequação das palavras isoladas exigem escuta
  e revisão de falantes nativos; áudio não silencioso não comprova qualidade.
- `git diff --check`: aprovado.

## Pendências reais

1. **Hebraico embutido:** não implementado; continua usando a voz do aparelho.
2. **Definições longas:** infraestrutura implementada, sem os dados traduzidos.
   Nenhuma chamada paga foi feita nesta revisão; o banco não foi regenerado.
   As estimativas existentes são indicativas e não constituem orçamento
   validado: precisam considerar prompts, tentativas e tokenização por idioma.
3. **Android e iPhone:** nenhum teste físico ou build dessas plataformas foi
   realizado aqui. Silêncio, bloqueio de tela, reprodução e compatibilidade
   nativa continuam pendentes.
4. **Distribuição do áudio:** o uso de componentes GPL exige verificar as
   obrigações aplicáveis, inclusive fonte correspondente e termos de
   distribuição. Apenas manter atribuição não demonstra conformidade.
   Referências: [GPL, seção 6](https://www.gnu.org/licenses/gpl-3.0.html#section6)
   e [FAQ da GNU](https://www.gnu.org/licenses/gpl-faq.html#GPLInProprietarySystem).
5. **Pronúncia:** revisão humana não realizada. O teste de síntese confirma
   integração técnica, não naturalidade ou exatidão fonética.

O push da branch e um PR em rascunho permitem revisar e continuar essas
pendências. Não representam conclusão dos dois objetivos originais.
