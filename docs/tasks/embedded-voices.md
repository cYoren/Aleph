# Tarefa para outro agente: vozes embutidas no Aleph

Copie este arquivo inteiro como instrução para o agente responsável.

## Entrega desejada

Implemente no Aleph uma voz de hebraico israelense moderno (`he-IL`) e uma voz
de grego moderno (`el-GR`) que acompanhem o aplicativo. Ao tocar no alto-falante
ou em reproduzir capítulo, o usuário deve ouvir imediatamente, inclusive sem
internet e sem instalar vozes nas configurações do telefone.

Repositório local: `/home/gustvmar/Documents/Coding/Aleph`.
GitHub: https://github.com/cYoren/Aleph.
Leia `AGENTS.md`, `README.md`, `CONTRIBUTING.md` e `ROADMAP.md` antes de trabalhar.
Use uma branch própria e preserve alterações de outros agentes. Existe uma
alteração anterior em `lib/main.dart` para testes locais no Linux; não a reverta.

## Diagnóstico confirmado em 16/10/2026

- O projeto é Flutter; plataformas de produto: Android, iOS e macOS.
- `flutter_tts` em `lib/features/audio/recitation_service.dart` usa exclusivamente
  as vozes do sistema. Não há motor próprio nem modelos de voz no pacote.
- `availabilityFor()` pode responder `voiceMissing`; o botão atual abre o
  instalador do sistema por `voice_setup.dart`. Isso ainda depende do usuário.
- A mesma classe atende capítulos e palavras isoladas. Mantenha as duas funções.
- `recitation_provider.dart` avança após a conclusão real de cada fala e usa
  uma geração para cancelar execuções antigas. Preserve essa sincronização.
- `recitation_text.dart` retira cantilação hebraica e converte grego politônico
  em monotônico para as vozes modernas. Avalie o texto exigido pelo modelo
  escolhido; preserve a capacidade de pronunciar palavras com sinais vocálicos.
- O áudio de iOS precisa respeitar a sessão de reprodução, funcionar com o
  interruptor de silêncio e ser verificado com a tela bloqueada.
- Este trabalho NÃO foi implementado na branch de correções de idioma.

## Pesquisa inicial, sem decisão de modelo

Sherpa-ONNX tem exemplos oficiais de síntese em Flutter e de inclusão de modelos
como assets: https://github.com/k2-fsa/sherpa-onnx/tree/master/flutter-examples/tts
e https://github.com/k2-fsa/sherpa-onnx/blob/master/flutter-examples/README.md.
É um candidato para avaliar, não uma garantia de compatibilidade ou licença
de qualquer voz específica.

Há uma voz grega Piper `el_GR/rapunzelina/low`. O cartão consultado informa
16 kHz, uma locutora e dataset CC0:
https://huggingface.co/rhasspy/piper-voices/blob/main/el/el_GR/rapunzelina/low/MODEL_CARD.
Ainda é preciso verificar todos os componentes redistribuídos, incluindo pesos,
motor, fonemizador e dependências nativas. A licença do motor não substitui
a licença de cada modelo. A qualidade e o sotaque precisam de avaliação auditiva.

Ainda não há voz hebraica escolhida ou licença de redistribuição validada.
Pesquise uma opção adequada para leitura bíblica apontada, com sotaque israelense.
Não anuncie as duas vozes como prontas tendo implementado apenas o grego.

## Implementação e limites

1. Valide candidatos, tamanho, licença, pronúncia e desempenho antes da integração.
   Não troque a licença do aplicativo para acomodar uma dependência sem registrar
   a incompatibilidade. Preserve atribuições e documente fontes e versões.
2. Inclua motor, pesos, vocabulários e fonemização necessários no pacote final.
   Um download automático no primeiro uso não satisfaz "embutido" nem o teste
   de primeira execução em modo avião.
3. Se modelos grandes não forem versionados, forneça um script reproduzível de
   preparação com URLs fixadas, hashes e verificação obrigatória no build. A
   distribuição final deve conter todos os arquivos. Não use placeholders.
4. Use o motor embutido como caminho padrão. Uma opção adicional de voz do sistema
   pode existir, mas a experiência principal não pode exigir instalação externa.
5. Preserve `RecitationService` ou adapte seus consumidores de maneira coerente:
   disponibilidade, configuração, conclusão de fala, erro, parada e descarte.
   Faça síntese fora da interface para evitar congelamentos. Limite memória e cache.
6. Trate mudança de capítulo, fala de palavra durante capítulo, toques repetidos,
   troca de idioma e velocidade sem sobreposição, falas antigas ou espera infinita.
7. Mantenha os ritmos de aprendizagem e o destaque do versículo sincronizado com
   o som. Parar deve interromper síntese e reprodução, inclusive na preparação.
8. Traduza novas mensagens em todos os oito ARBs e regenere as localizações.
   Atualize configurações, onboarding, README e ROADMAP: atualmente dizem que a
   voz depende do aparelho. Remova instruções de instalar vozes da experiência
   padrão somente quando o áudio embutido realmente funcionar.
9. Não adicione serviços de voz na nuvem, cobrança por uso, chave de API ou servidor.
   Não publique nas lojas nem altere assinaturas de distribuição nesta tarefa.

## Critérios de aceite

- Instalação limpa, sem internet e sem vozes hebraica/grega no sistema: ouvir
  Gênesis 1 em hebraico, João 1 em grego e palavras isoladas das duas línguas.
- Ouvir manualmente amostras e fornecer arquivos de prévia e comandos completos
  para reproduzi-los. Submeter a pronúncia à revisão de falantes das duas línguas.
- Parar durante preparação e durante fala; mudar de capítulo e velocidade;
  repetir reproduzir/parar; sair e voltar; verificar erros recuperáveis.
- Testes automatizados de contrato da fala, cancelamento, troca de idioma,
  seleção do motor embutido sem voz do sistema e inclusão real dos assets.
- Executar `flutter analyze`, `flutter test` e `./scripts/validate_release.sh`.
- Builds Android, iOS e macOS, com verificação de bibliotecas nativas e assets.
  Medir tamanho adicional, tempo até o primeiro som e memória. Verificar suporte
  às exigências atuais de páginas de memória do Android para bibliotecas nativas.
- Relatar claramente os aparelhos testados. Um teste com motor simulado ou uma
  compilação no Linux não comprova som no iPhone ou Android. Se faltar acesso ao
  hardware, declarar esse teste pendente sem afirmar que o trabalho foi validado.
- Entregar mudanças revisáveis e relatório com licenças, versões, hashes,
  resultados dos testes e limitações reais. Não incluir credenciais ou banco
  gerado no commit.
