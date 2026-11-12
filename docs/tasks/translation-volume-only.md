# Copiar integralmente para o agente de tradução

Sua tarefa é **produzir dados de tradução**, sem decidir arquitetura nem alterar
código do aplicativo. Não pesquise motores de voz, não substitua bibliotecas e
não publique nada. O responsável pela integração fará a revisão posterior.

## Ambiente e preparação

- Projeto: `/home/gustvmar/Documents/Coding/Aleph`.
- Base: branch `feat/embedded-voices-lexicon-i18n`, com as últimas correções.
- Leia `AGENTS.md`. Preserve commits e alterações existentes.
- Banco de origem: `assets/bible.db`, somente leitura; não o versione.
- Há um pacote exportado em `/tmp/aleph-lexicon-source.json`. Se não estiver
  disponível, gere-o com o comando completo:

```bash
cd /home/gustvmar/Documents/Coding/Aleph
python3 scripts/export_lexicon_definitions.py --bundle /tmp/aleph-lexicon-source.json
```

O pacote tem dois campos em `texts`: `definition` e `extended_definition`.
Cada campo é um objeto `{SHA256_DO_TEXTO_ORIGINAL: TEXTO_ORIGINAL}`. Há 13.069
definições e 12.842 entradas estendidas únicas: 25.911 textos e 3.631.770
caracteres de origem. Os textos já estão deduplicados; não os deduplique por
Strong's nem por semelhança. Traduza cada hash uma vez por idioma e campo.

## Únicos arquivos de entrega

Produza estes sete arquivos JSON UTF-8:

```text
data/lexicon_translations/pt.json
data/lexicon_translations/es.json
data/lexicon_translations/de.json
data/lexicon_translations/fr.json
data/lexicon_translations/ru.json
data/lexicon_translations/zh.json
data/lexicon_translations/ko.json
```

Idiomas: português brasileiro, espanhol, alemão, francês, russo, chinês
simplificado e coreano, respectivamente. Todo conteúdo em inglês nos dois
campos deve ser traduzido integralmente para cada idioma. Não retraduza a Bíblia,
os menus ou os significados curtos, que já têm tradução.

Formato obrigatório por arquivo:

```json
{
  "_meta": {
    "lang": "pt",
    "language": "Brazilian Portuguese",
    "method": "machine-translation",
    "provider": "NOME_REAL_DO_AGENTE_OU_PROVEDOR",
    "model": "MODELO_REAL_UTILIZADO_OU_NOT_REPORTED_SE_NAO_FOR_INFORMADO",
    "revision": 1,
    "human_reviewed": false
  },
  "definition": {
    "HASH_ORIGINAL_SEM_ALTERAR": "Tradução integral desta definição"
  },
  "extended_definition": {
    "HASH_ORIGINAL_SEM_ALTERAR": "Tradução integral desta entrada estendida"
  }
}
```

Os exemplos acima são só o formato: substitua os marcadores pelos dados reais.
Cada campo deve conter **todos** os hashes do campo correspondente no pacote.
Nunca recalcule a chave usando a tradução. Não acrescente hashes desconhecidos,
marcadores, resumos ou strings vazias. Não declare revisão humana inexistente.

## Regras de conteúdo já decididas

1. Traduza todo o texto explicativo, mantendo todos os sentidos, exemplos,
   enumerações, negações, qualificações e referências. Não acrescente exegese,
   opinião teológica ou sentidos que não estejam no original.
2. Preserve exatamente as palavras hebraicas e gregas, incluindo vogais,
   acentos e sinais combinantes. Preserve a quantidade de ocorrências dessas
   palavras. Não normalize Unicode, não translitere nem substitua por sinônimos.
3. Preserve exatamente os identificadores Strong's, inclusive zeros e sufixos:
   `H0430`, `G26`, `H0871A`. Não acrescente nem retire identificadores.
4. Preserve referências bíblicas e abreviações acadêmicas como BDB, LXX, MT,
   `v.`, `v.s.` e `q.v.`. Traduza a prosa ao redor delas.
5. Algumas entradas estendidas não contêm prosa inglesa, apenas palavras
   originais e abreviações, como `Βοσόρ v. Βεώρ.`. Há 56 textos sem palavras
   latinas de duas letras consecutivas no pacote atual. Copie esses textos
   integralmente em todos os idiomas; não invente uma tradução para fazê-los
   parecer diferentes. A exceção é reconhecida pelo validador. Não estenda
   essa regra a definições em inglês.
6. Use termos consistentes de linguística e estudo bíblico. A tradução é
   automática e deve ser identificada como tal; uma tradução fluente não
   substitui posterior revisão especializada.

## Execução de volume

- Use sua própria capacidade de tradução. Não contrate serviços externos nem
  dispare uma nova API paga sem autorização específica para esse gasto.
- Trabalhe em lotes pequenos e salve progresso frequentemente, por idioma e
  campo. Retome pelos hashes ausentes; preserve traduções corretas já salvas.
- Não coloque milhares de entradas numa única resposta que possa ser truncada.
  Escreva os dados nos arquivos e mantenha JSON válido entre checkpoints.
- Não use um glossário curto ou regras de substituição de palavras para fingir
  que traduziu a definição completa. Não copie inglês para preencher lacunas.
- Não altere scripts ou validadores para fazer uma entrega incompleta passar.

## Verificação obrigatória antes de devolver

```bash
cd /home/gustvmar/Documents/Coding/Aleph
python3 scripts/validate_translation_delivery.py
```

O comando deve terminar com `OK` e código zero. Ele verifica sete idiomas,
hashes, cobertura, campos vazios, inglês copiado, chaves JSON duplicadas e
preservação de hebraico, grego e Strong's. Corrija as entradas rejeitadas;
não afrouxe o contrato. Essa validação não comprova correção semântica.

Não aplique os caches ao banco nesta tarefa, não aumente a versão do banco,
não modifique o aplicativo e não execute os fluxos de publicação. A integração
e a validação do produto ficam com o agente responsável pela arquitetura.

Devolva os sete arquivos completos em commits que incluam apenas esses dados,
mais um relatório curto de cobertura por idioma/campo, modelo utilizado,
limitações conhecidas e resultado do comando. Se não completar tudo, informe
os hashes ainda ausentes sem chamar a tarefa de concluída.
