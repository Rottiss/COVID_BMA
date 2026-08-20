# Dicionário de dados da fase 1

**Base de partida:** `dadosv6.xlsx`  
**Aba analítica:** `raw`  
**Observações:** 184 municípios  
**Colunas:** 45  
**Estado:** classificação atualizada após a verificação local de 18 de agosto de 2026.

## Estados usados

| Estado | Significado |
|---|---|
| Confirmada | definição e associação municipal passaram nas conferências já realizadas |
| Corrigir | há erro identificado na associação, unidade, ausência ou definição |
| Decidir | a construção depende de uma escolha de período, unidade ou especificação |
| Verificar | faltam confirmação de fonte, ano, campo original ou associação municipal |
| Derivada | deve ser recalculada depois da correção dos campos de origem |

“Confirmada” não dispensa a validação automática da fase 3. O termo indica apenas que as conferências realizadas até agora não encontraram divergência.

## Identificador e desfechos

| Código atual | Nome para o texto | Papel | Unidade atual | Período | Fonte registrada | Estado | Ação da fase 1 |
|---|---|---|---|---|---|---|---|
| `Municipios` | Município | identificador | texto | não se aplica | nomes presentes nas fontes | Corrigir | adicionar código IBGE e padronizar grafia sem usar nome como chave principal |
| `covtotal` | Casos confirmados acumulados de COVID-19 | numerador auxiliar | casos | até 31/07/2020 | DATASUS/SVS, arquivo `covidsus.csv` | Corrigir | refazer por código IBGE; três municípios estão trocados |
| `cov100k` | Casos confirmados por 100 mil habitantes | desfecho principal | casos por 100 mil habitantes | até 31/07/2020 | derivada de casos e população | Derivada | recalcular após corrigir casos e população |
| `obito` | Óbitos acumulados por COVID-19 | numerador auxiliar | óbitos | até 31/07/2020 | DATASUS/SVS, arquivo `covidsus.csv` | Corrigir | refazer por código IBGE; três municípios estão trocados |
| `obito100k` | Óbitos por 100 mil habitantes | desfecho principal | óbitos por 100 mil habitantes | até 31/07/2020 | derivada de óbitos e população | Derivada | recalcular após corrigir óbitos e população |
| `letal` | Taxa de letalidade | desfecho principal | óbitos divididos por casos | até 31/07/2020 | derivada de casos e óbitos | Derivada | recalcular; substituir o código divergente `tax.mort` no glossário |

## Covariáveis e denominadores

| Código atual | Nome para o texto | Dimensão | Unidade atual | Ano ou período registrado | Fonte registrada ou candidata | Estado | Ação da fase 1 |
|---|---|---|---|---|---|---|---|
| `pop ` | População estimada | demográfica | habitantes | 2019 | DATASUS, com valor também presente na base de COVID | Corrigir | remover espaço do código e refazer por código IBGE; três municípios estão trocados |
| `recursofed` | Transferências federais para combate à COVID-19 | fiscal durante a pandemia | declarado por 100 mil habitantes | março a julho de 2020 no rótulo | Portal da Transparência; `transferencias_coronavirus.csv` e `transferencias_coronavirus1.csv` | Decidir | definir período e arquivo de autoridade; refazer por código IBGE |
| `auxem` | Auxílio emergencial | fiscal durante a pandemia | declarado por 100 mil habitantes | abril a julho de 2020 no rótulo | Portal da Transparência; `auxilio_emergencial.csv` e `LIMPOS/auxilio.csv` | Decidir | confirmar se os dados cobrem abril e maio ou abril a julho; refazer por código IBGE |
| `area` | Área territorial | territorial | km² | 2019 | IBGE; campo `AR_MUN_2019` de `LIMPOS/areamunicipio.xls` | Corrigir | refazer por código IBGE; Santana do Acaraú, Santana do Cariri e Santa Quitéria estão desalinhados |
| `densidade` | Densidade demográfica | territorial | habitantes por km² | 2019 | derivada de população e área | Derivada | recalcular depois da correção da população |
| `pibpc` | Produto Interno Bruto per capita | socioeconômica | reais por habitante | 2018 | IBGE, arquivo `LIMPOS/pibpc2018.xlsx` | Confirmada | registrar campo original e unidade monetária |
| `idhm` | Índice de Desenvolvimento Humano Municipal | socioeconômica | índice de 0 a 1 | 2010 | Atlas Brasil/PNUD | Corrigir | refazer por código IBGE; três municípios estão trocados |
| `idm` | Índice de Desenvolvimento Municipal | socioeconômica | índice do IPECE | 2018 | IPECE | Confirmada | registrar edição e campo original |
| `desp.saude` | Despesa municipal com saúde e saneamento | fiscal pré-pandemia | R$ por 100 mil habitantes | 2018 | IPEA/STN | Confirmada | convertida em 18/08/2026 por `main/.codex_tmp/convert_despesas_100k.mjs` (`valor absoluto ÷ população × 100.000`, aplicado direto na aba `raw`); confirmado em 19/08/2026 por correlação praticamente nula com a população (0,027, mesmo padrão de `recursofed`) como conferência secundária |
| `desp.educ` | Despesa municipal com educação e cultura | fiscal pré-pandemia | R$ por 100 mil habitantes | 2018 | IPEA/STN | Confirmada | convertida em 18/08/2026 por `main/.codex_tmp/convert_despesas_100k.mjs` (`valor absoluto ÷ população × 100.000`, aplicado direto na aba `raw`); confirmado em 19/08/2026 por correlação fraca e negativa com a população (-0,206) como conferência secundária |
| `ideb5` | IDEB dos anos iniciais do ensino fundamental | educação | índice IDEB | 2019 | INEP | Verificar | conferir associação por código e definir série ou etapa exata |
| `ideb9` | IDEB dos anos finais do ensino fundamental | educação | índice IDEB | 2019 | INEP, arquivo `DADOS/dados.xlsx` | Corrigir | refazer por código IBGE; 19 municípios estão permutados |
| `ideb3` | IDEB do 3º ano do ensino médio | educação | índice IDEB | 2019 | INEP | Verificar | conferir associação por código e disponibilidade municipal |
| `tax.agua` | Cobertura urbana de abastecimento de água | infraestrutura | percentual | 2019 | IPECE; `possible data/aguaporcento.xlsx` | Confirmada | usar a coluna urbana de 2019; os 184 valores foram conciliados |
| `con.energia` | Consumo de energia elétrica | infraestrutura e atividade | MWh no arquivo `raw`; por 100 mil habitantes no modelo | 2019 | IPECE/Coelce, arquivo `LIMPOS/energia.xlsx` | Confirmada | preservar o total na planilha e calcular `energia100k = con.energia/pop × 100.000` no R |
| `tax.hom` | Taxa de homicídios | violência | homicídios por 100 mil habitantes | 2019 | SIM-DATASUS; `LIMPOS/homicidios.xls` | Corrigir | recalcular número de homicídios dividido pela população e multiplicado por 100 mil; corrigir três associações municipais e remover a alegação não sustentada de homicídios ocultos |
| `eleitas.fem` | Proporção de mulheres eleitas | política | percentual | eleição de 2016 no registro da base | TSE; planilha intermediária `possible data/generoeleicoes.csv` | Verificar | os 184 percentuais e numeradores femininos foram conciliados; confirmar cargo, denominador e extração original |
| `bolsaf` | População beneficiária do Programa Bolsa Família | proteção social | percentual | 2020 | Ministério da Cidadania/SENARC; `possible data/bolsafamilia.xlsx` | Verificar | os 184 valores foram conciliados; confirmar mês de referência e população denominadora |
| `sus1k` | Unidades de saúde vinculadas ao SUS | saúde | unidades por mil habitantes | 2019 | SESA; `possible data/susmilhabitante.xlsx` | Confirmada | os 184 valores coincidem após arredondamento para duas casas; recalcular depois de corrigir a população |
| `leitos1k` | Leitos vinculados ao SUS | saúde | leitos por mil habitantes | 2019 | IPECE/SESA; campo “Ligados ao SUS — Total” de `leitos_ipece.xlsx` | Corrigir | recalcular após corrigir a população; 170 de 175 comparações coincidiram, cinco usam denominadores desalinhados e nove não têm valor na fonte |
| `prof1k` | Profissionais de saúde vinculados ao SUS | saúde | profissionais por mil habitantes | 2019 | IPECE/SESA; total de 2019 em `profissionais_ipece.xlsx` | Corrigir | recalcular após corrigir a população; 179 de 184 comparações coincidiram e cinco usam denominadores desalinhados |
| `metrop` | Município integrante de região metropolitana | territorial | indicador 0 ou 1 | não registrado | fonte registrada na planilha é inadequada | Verificar | definir a composição territorial e o ano de referência |
| `semiarido` | Município integrante do semiárido | territorial | indicador 0 ou 1 | 2020 no registro da base | IPECE; `possible data/Tabela 1.4.1 (Planilha)_data.csv` | Verificar | os 184 indicadores foram conciliados; registrar edição, norma territorial e ano da delimitação |
| `pop.rural` | Proporção da população rural | demográfica | proporção de 0 a 1 | 2010 | IBGE | Corrigir | corrigir a descrição: população rural dividida pela população total |
| `aliadogov` | Alinhamento partidário do prefeito com o governo federal | política | indicador 0 ou 1 | classificação de 2019 | TRE/TSE e critério de apoio legislativo | Verificar | documentar partidos classificados como aliados, fonte e regra de corte |
| `votos` | Proporção de votos válidos do prefeito eleito | política | proporção de 0 a 1 | eleição de 2016 | arquivo intermediário `DADOS/eleicoes.csv`, derivado de dados eleitorais | Confirmada | manter `% Válidos/100`; registrar turno e referência da extração na bibliografia de dados |
| `ivs` | Índice de Vulnerabilidade Social | vulnerabilidade | índice de 0 a 1 | 2010 | IPEA | Corrigir | refazer por código IBGE; 171 associações municipais estão erradas; decidir uso no modelo |
| `ivs.infra` | IVS Infraestrutura Urbana | vulnerabilidade | índice de 0 a 1 | 2010 | IPEA | Corrigir | refazer por código IBGE; não usar junto ao agregado sem especificação separada |
| `ivs.capital` | IVS Capital Humano | vulnerabilidade | índice de 0 a 1 | 2010 | IPEA | Corrigir | refazer por código IBGE; não usar junto ao agregado sem especificação separada |
| `ivs.renda` | IVS Renda e Trabalho | vulnerabilidade | índice de 0 a 1 | 2010 | IPEA | Corrigir | refazer por código IBGE; não usar junto ao agregado sem especificação separada |
| `emprego` | Proporção da população em empregos formais | mercado de trabalho | proporção de 0 a 1 | não registrado no glossário | arquivo `ultimas variaveis/empregoformal.xlsx` | Confirmada | registrar ano, numerador e população denominadora |
| `ex.pobr` | Proporção da população em extrema pobreza | vulnerabilidade | proporção de 0 a 1 | não registrado no glossário | IPECE | Confirmada | registrar ano, linha de renda, numerador e denominador |
| `tmi` | Taxa de mortalidade infantil | saúde | óbitos menores de um ano por mil nascidos vivos | 2019 | IPECE/SESA; `ultimas variaveis/TMI.xlsx` | Corrigir | restaurar dez ausências como `NA`; conferir a divergência de Uruburetama |
| `imuni` | Cobertura média de imunização em menores de um ano | saúde | proporção na base atual | 2019 | IPECE/SESA; `ultimas variaveis/vacinas.xlsx` | Corrigir | refazer por código IBGE; 17 municípios estão permutados; documentar valores superiores a 1 |
| `idosos` | Proporção da população com 60 anos ou mais | demográfica | proporção de 0 a 1 | 2019 | DATASUS | Confirmada | registrar campo etário e população denominadora |
| `int.circ` | Internações por doenças do aparelho circulatório | saúde | internações por 100 mil habitantes | 2019 | DATASUS/SIH; capítulo IX da CID-10, por local de residência | Confirmada | reconstruir por código municipal com a fórmula `internações/população × 100.000` |
| `int.resp` | Internações por doenças do aparelho respiratório | saúde | internações por 100 mil habitantes | 2019 | DATASUS/SIH; capítulo X da CID-10, por local de residência | Confirmada | reconstruir por código municipal com a fórmula `internações/população × 100.000` |
| `int.diab` | Internações por diabetes mellitus | saúde | internações por 100 mil habitantes | 2019 | DATASUS/SIH; diabetes mellitus, por local de residência | Confirmada | reconstruir por código municipal com a fórmula `internações/população × 100.000` |
| `int.asma` | Internações por asma | saúde | internações por 100 mil habitantes | 2019 | DATASUS/SIH; asma, por local de residência | Confirmada | reconstruir por código municipal com a fórmula `internações/população × 100.000` |

## Decisões de mensuração

| ID | Decisão | Estado | Regra provisória |
|---|---|---|---|
| D01 | Chave municipal | definida | usar código IBGE; nome será apenas rótulo e campo de conferência |
| D02 | Corte dos desfechos | definida provisoriamente | usar o último registro disponível até 31/07/2020 para cada município |
| D03 | Período das transferências federais | aberta | escolher um único intervalo e o arquivo que representa esse intervalo |
| D04 | Período do auxílio emergencial | aberta | confirmar se a análise pretende abril e maio ou abril a julho de 2020 |
| D05 | Unidade das despesas municipais | definida em 19/08/2026 | `desp.saude` e `desp.educ` já estão em R$ por 100 mil habitantes na base atual, convertidas em 18/08/2026 por `main/.codex_tmp/convert_despesas_100k.mjs`; correlação praticamente nula com a população usada só como conferência secundária. O rótulo antigo ("valor absoluto") estava desatualizado |
| D06 | Representação do IVS | definida | excluir `ivs` das estimações e usar `ivs.infra`, `ivs.capital` e `ivs.renda` como covariáveis separadas |
| D07 | Ausências de mortalidade infantil | definida | preservar os dez `NA` na base e excluir `tmi` de todas as estimações e sensibilidades |
| D08 | Escala de percentuais | definida | preservar a unidade documentada de cada fonte; padronizar as covariáveis no BMS, o que elimina diferenças entre escalas 0–1 e 0–100 na estimação |
| D09 | Variáveis medidas durante a pandemia | definida | excluir `recursofed` e `auxem` do modelo principal e incluí-las apenas no modelo ampliado, com interpretação associativa |
| D10 | Variáveis de escala municipal | definida | usar despesas e energia por 100 mil habitantes; manter população, área e densidade em nível antes da padronização; estimar uma sensibilidade sem Fortaleza |
| D11 | Nomes das variáveis | definida | usar códigos sem espaços e nomes completos no manuscrito; `letal` substitui `tax.mort` |
| D12 | Identificação de fontes | em andamento | cada variável deverá ter arquivo, campo original, URL ou instituição, ano e fórmula |
| D13 | Transformação da letalidade | definida | usar o logit empírico `log((obito + 0,5)/(covtotal - obito + 0,5))` no BMA principal e manter `letal` em nível como sensibilidade |

## Problemas do glossário original

- O glossário usa `tax.mort`, mas a aba `raw` usa `letal`.
- A descrição de `pop.rural` apresenta a razão no sentido inverso ao valor armazenado.
- O glossário original estava desatualizado quanto às despesas. A base ativa já contém `desp.saude` e `desp.educ` em reais por 100 mil habitantes.
- Os períodos fiscais descritos nos rótulos não coincidem claramente com os arquivos intermediários encontrados.
- `metrop`, `emprego` e `ex.pobr` não têm ano registrado.
- Vários links do INEP e do DATASUS contêm `http://http://` e precisam ser corrigidos no registro de fontes.
- A planilha não informa código IBGE, campo original e fórmula de transformação para cada variável.

## Critério de conclusão da fase 1

A fase 1 termina quando cada uma das 45 colunas tiver:

1. nome técnico e nome para o manuscrito;
2. papel no modelo;
3. unidade e escala;
4. ano ou período;
5. instituição, arquivo e campo original;
6. fórmula de transformação;
7. tratamento de ausências;
8. chave municipal;
9. decisão de permanência no modelo principal ou em análise de sensibilidade.

Enquanto houver decisões abertas nas variáveis fiscais, despesas, IVS, escalas percentuais e temporalidade, a fase 2 não deve reconstruir essas colunas como definitivas.
