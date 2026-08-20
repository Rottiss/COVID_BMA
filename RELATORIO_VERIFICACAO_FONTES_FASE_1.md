# Relatório de verificação das fontes — fase 1

**Data da conferência:** 18 de agosto de 2026  
**Base examinada:** `COVID_BMA/dadosv6.xlsx`, aba `raw`  
**Escopo:** 18 variáveis inicialmente classificadas como “Verificar”  
**Regra:** nenhuma célula da base e nenhum script foram alterados.

## Síntese

A rodada permitiu encerrar a verificação local de cinco variáveis: `votos`, `int.circ`, `int.resp`, `int.diab` e `int.asma`. Quatro variáveis foram reclassificadas para “Corrigir”: `area`, `tax.hom`, `leitos1k` e `prof1k`. Nelas, a fonte e a fórmula foram identificadas, mas há associações municipais ou denominadores que precisam ser refeitos por código IBGE. As nove restantes continuam pendentes porque os arquivos locais não bastam para documentar a série, o universo ou a regra de classificação.

Depois desta rodada, a distribuição das 45 colunas passa a ser: 11 confirmadas, 17 com correção identificada, 4 dependentes de decisão, 4 derivadas e 9 ainda em verificação.

## Resultados por variável

| Variável | Resultado da conferência | Estado após a rodada |
|---|---|---|
| `area` | O campo `AR_MUN_2019`, do arquivo `DADOS/LIMPOS/areamunicipio.xls`, confirmou 181 dos 184 valores. Santana do Acaraú, Santana do Cariri e Santa Quitéria estão associados a áreas de outros municípios. | Corrigir |
| `ideb5` | A planilha registra INEP, 2019, mas não foi localizado arquivo-fonte independente dos anos iniciais que permita conferir a série municipal por código. | Verificar |
| `ideb3` | A planilha registra INEP, 2019, mas não foi localizado arquivo-fonte independente do ensino médio que permita conferir a disponibilidade e a série municipal. | Verificar |
| `tax.agua` | O rótulo atribui o indicador ao IPECE em 2019. Não foi localizado arquivo bruto local que identifique o universo urbano, o denominador e o campo original. | Verificar |
| `tax.hom` | O arquivo `DADOS/LIMPOS/homicidios.xls` contém o número de homicídios do SIM-DATASUS em 2019. A fórmula `homicídios/população × 100.000` reproduz os valores não vazios, exceto Santana do Acaraú, Santana do Cariri e Santa Quitéria. A fonte local não sustenta a descrição de “homicídios ocultos” atribuída ao Atlas da Violência. | Corrigir |
| `eleitas.fem` | O rótulo informa TSE e eleição de 2016, mas não há arquivo bruto local com candidaturas eleitas e sexo que permita confirmar numerador, denominador e cargo abrangido. | Verificar |
| `bolsaf` | O rótulo informa IPECE e 2020, mas não foi localizado arquivo local que fixe mês, número de beneficiários e população denominadora. | Verificar |
| `sus1k` | O arquivo disponível, `DADOS/LIMPOS/unidadesus.xlsx`, refere-se a 2015. Seus valores não reproduzem a coluna rotulada como 2019: apenas 40 de 184 ficam dentro de 0,005 unidade por mil. | Verificar |
| `leitos1k` | O numerador correto é “leitos ligados ao SUS”, em 2019, no arquivo `DADOS/leitos_ipece.xlsx`. A fórmula por mil habitantes coincide em 170 dos 175 municípios com valor-fonte; há nove ausências na fonte e cinco divergências ligadas ao denominador municipal. | Corrigir |
| `prof1k` | O numerador é o total de profissionais de saúde ligados ao SUS em 2019, no arquivo `DADOS/profissionais_ipece.xlsx`. A fórmula por mil habitantes coincide em 179 dos 184 municípios; as cinco exceções são Barbalha, Missão Velha, Santa Quitéria, Santana do Acaraú e Santana do Cariri. | Corrigir |
| `metrop` | A atribuição a DATASUS/SVS é inadequada. Não foi localizada lista territorial local com composição e ano de referência. | Verificar |
| `semiarido` | A planilha registra IPECE e 2020, mas não foi localizada a lista ou norma territorial que produziu o indicador municipal. | Verificar |
| `aliadogov` | Os 183 municípios conciliados coincidem com a coluna intermediária de `DADOS/eleicoes.csv`. Ainda faltam a fonte da classificação partidária, a relação de partidos aliados e a operacionalização do corte superior a 50%. | Verificar |
| `votos` | Os 183 municípios conciliados reproduzem exatamente `% Válidos/100` em `DADOS/eleicoes.csv`. O arquivo documenta a proporção usada, embora o turno e a extração original ainda devam constar na referência final. | Confirmada |
| `int.circ` | Os 183 municípios conciliados reproduzem `internações/população × 100.000` na planilha intermediária `ultimas variaveis/saude.xlsx`. O arquivo bruto registra capítulo IX da CID-10, local de residência e período de 2019. | Confirmada |
| `int.resp` | Os 183 municípios conciliados reproduzem a fórmula por 100 mil. O arquivo bruto registra capítulo X da CID-10, local de residência e período de 2019. | Confirmada |
| `int.diab` | Os 183 municípios conciliados reproduzem a fórmula por 100 mil. O recorte é diabetes mellitus, por local de residência, em 2019. | Confirmada |
| `int.asma` | Os 183 municípios conciliados reproduzem a fórmula por 100 mil. O recorte é asma, por local de residência, em 2019. | Confirmada |

## Padrões de erro encontrados

As divergências não são aleatórias. Santana do Acaraú, Santana do Cariri e Santa Quitéria reaparecem em `area` e `tax.hom`; esses municípios já estavam envolvidos em desalinhamentos de outras colunas. Barbalha e Missão Velha se somam a eles em `leitos1k` e `prof1k`. Isso reforça a decisão de reconstruir a base por código IBGE, sem tentar corrigir células isoladas na planilha recebida.

Nas internações, a verificação cobriu 183 municípios porque uma grafia não foi conciliada automaticamente entre os arquivos. Como todos os registros conciliados reproduziram exatamente os valores e a fórmula, a pendência é de chave textual, não de mensuração. A reconstrução da fase 2 deverá resolver isso pelo código municipal.

## Pendências documentais antes da reconstrução

Ainda são necessárias fontes de autoridade para:

1. IDEB dos anos iniciais e do 3º ano do ensino médio em 2019;
2. cobertura urbana de água em 2019;
3. mulheres eleitas em 2016, com cargo e denominador;
4. beneficiários do Programa Bolsa Família, com mês de referência;
5. unidades de saúde ligadas ao SUS em 2019;
6. composição das regiões metropolitanas no ano adotado;
7. delimitação do semiárido vigente no ano adotado;
8. regra e fonte da classificação de partidos aliados ao governo federal.

Essas buscas devem priorizar INEP, TSE, IPECE, IBGE e legislação territorial. Nenhuma fonte externa foi incorporada nesta rodada.

## Consequência para a fase 2

A reconstrução pode começar pelos identificadores, desfechos, área, homicídios, votos e internações, desde que use código IBGE e registre as fórmulas. `leitos1k` e `prof1k` devem ser recalculadas somente depois de corrigida a população. As nove variáveis ainda marcadas como “Verificar” não devem entrar como colunas definitivas até o fechamento de suas fontes e definições.
