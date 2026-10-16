# Decisões técnicas ainda abertas

Esta pesquisa complementa a revisão; não constitui uma integração concluída.
O responsável pela arquitetura continua responsável por selecionar e testar
modelos, runtime, licenças e empacotamento. A tarefa de volume de tradução está
isolada em `translation-volume-only.md` e não deve decidir esses pontos.

## Hebraico: a pesquisa anterior não é uma prova de impossibilidade

Fontes primárias consultadas novamente:

- [Pocket TTS ONNX](https://huggingface.co/thewh1teagle/pocket-tts-onnx): API
  consultada informou revisão `110f5251188e9407b4f724acdd8b0dfd0b20692a`, modelo
  público e metadados CC BY 4.0. O cartão atual inclui um adaptador de hebraico;
  o conjunto de inferência informa aproximadamente 177 MB de modelo, 1,4 MB de
  configuração e 21 MB de G2P. Resultados indexados de busca ainda mostram
  CC BY-NC em alguns lugares; não misturar licenças de revisões diferentes.
  É necessário verificar também o adaptador, o G2P e as vozes de referência.
- [Blue ONNX v2](https://huggingface.co/notmax123/blue-onnx-v2), revisão
  `45dc85f1ac045ea62458a7492c5ae387610ac0af`: cartão declara MIT para pesos e
  ferramentas e inclui hebraico. [Código original](https://github.com/maxmelichov/BlueTTS).
  A variante [INT8](https://huggingface.co/notmax123/bluev2-onnx-int8), revisão
  `5f715c98cd96b1e88bce9ddfc18c709f7bb7e954`, tem cerca de 79 MB nos quatro
  grafos de síntese necessários. Não possui licença no próprio metadado da API:
  a vinculação de licença com o modelo de origem, os estilos e o G2P ainda
  precisa ser estabelecida antes de incluí-lo.
- `thewh1teagle/matcha-tts` e `thewh1teagle/mixer-tts`: buscas mostram modelos
  permissivos, mas a API de ambos retornou HTTP 401 nesta consulta. Não tratar
  um trecho indexado como um arquivo acessível ou uma licença verificada.

Nenhum desses modelos foi baixado, incorporado ou validado no Aleph nesta
etapa. Tamanho e rótulo de licença não bastam para comprovar adequação de sotaque,
fidelidade à pontuação hebraica bíblica, desempenho e distribuição em celulares.

## Grego: o problema do fonemizador é concreto

O próprio mantenedor do Sherpa documenta a intenção de retirar eSpeak NG por
conflitos de licença: [issue oficial #3731](https://github.com/k2-fsa/sherpa-onnx/issues/3731).
A issue descreve alternativas com léxico ou tokens previamente calculados,
mas isso não comprova que a biblioteca nativa atualmente incluída no Aleph
tenha sido compilada sem componentes GPL. A versão atual do projeto ainda é
Sherpa 1.13.8. Não bastam uma opção de runtime ou remover os arquivos de dados
se os binários continuam incorporando código sujeito às mesmas condições.

Antes de publicar: decidir e testar um caminho de distribuição compatível,
incluindo todos os componentes efetivos. Não marcar esta pendência como
resolvida apenas acrescentando atribuição, nem assumir que uma versão futura
já está disponível.

## O que permanece com o responsável pela arquitetura

1. Confirmar licença/proveniência e selecionar a solução hebraica.
2. Provar inferência local com o texto bíblico real, respeitando os sinais
   vocálicos e a tradição de pronúncia escolhida.
3. Resolver o caminho de runtime e distribuição do fonemizador grego.
4. Implementar e testar a integração, memória, velocidade e cancelamento.
5. Incorporar os sete caches de tradução quando forem entregues; revisar
   amostras semânticas, gerar o banco e atualizar a sua versão de distribuição.
6. Fazer builds de Android/iOS/macOS e validar em aparelhos reais. Esta máquina
   Linux não dispõe de Xcode ou aparelho conectado; essa evidência continua
   necessária e não é substituída por testes simulados.

Essas tarefas continuam abertas. O push e o PR em rascunho não as encerram.
