# Progresso do projeto COVID_BMA

**Atualizacao:** 19 de agosto de 2026  
**Fase atual:** redação e revisão do manuscrito (Fase 8).

## Arquivos ativos

| Arquivo | Funcao |
|---|---|
| `COVID_BMA.Rproj` | projeto do R |
| `dadosv6.xlsx` | base de trabalho com 184 municipios |
| `covid_bma.R` | preparacao, validacao, estimacao e diagnosticos |
| `DICIONARIO_DADOS_FASE_1.md` | definicoes e decisoes de mensuracao |
| `RELATORIO_VERIFICACAO_FONTES_FASE_1.md` | auditoria das fontes locais |

As versoes anteriores permanecem em `outdated`. Os resultados antigos permanecem em `resultados/piloto` e nao sao carregados pelas novas estimacoes.

## Especificacao atual

- Desfechos principais:
  - log dos casos por 100 mil habitantes;
  - log dos obitos por 100 mil habitantes com correcao de 0,5 obito;
  - logit empirico da letalidade com correcao de 0,5.
- Todas as variaveis dos modelos sao padronizadas no R.
- O IVS agregado e excluido. Os tres componentes entram separadamente.
- O consumo total de energia e preservado na planilha. O R calcula o consumo por 100 mil habitantes antes da padronizacao.
- Populacao, area e densidade permanecem em nivel. A retirada de Fortaleza verifica a influencia da assimetria.
- O modelo principal exclui transferencias federais e auxilio emergencial.
- O modelo ampliado acrescenta essas duas variaveis.
- A TMI foi excluida de todas as especificacoes. Os resultados produzidos anteriormente com essa variavel sao apenas historicos e nao entram nas tabelas nem na interpretacao.
- `hyper = "UIP"` permanece fixo. Nao ha sensibilidade com outro prior g.

## Estimacoes programadas

| Grupo | Cadeias por desfecho | Draws retidos | Burn-in |
|---|---:|---:|---:|
| Principal | 2 | 1.000.000 por cadeia | 200.000 por cadeia |
| Ampliado | 2 | 1.000.000 por cadeia | 200.000 por cadeia |
| Escalas alternativas | 1 | 500.000 | 100.000 |
| Sem Fortaleza | 1 | 500.000 | 100.000 |

O script marca uma estimacao como `aprovado` quando a menor Corr PMP e pelo menos 0,95 e, quando ha mais de uma cadeia, a maior diferenca de PIP nao ultrapassa 0,05. Esses valores sao regras operacionais do projeto, nao limites universais da literatura.

Nos modelos principal e ampliado, a primeira cadeia usa o ponto inicial padrao do BMS e a segunda parte do modelo nulo. As sementes tambem sao diferentes.

## Saidas

A execucao normal grava em `resultados/estimacoes`. Cada especificacao possui:

- objetos RDS de cada cadeia;
- logs do BMS;
- coeficientes consolidados;
- comparacao entre cadeias;
- diagnosticos individuais e resumo.

O arquivo `resultados/estimacoes/resumo_geral_diagnosticos.csv` registra os diagnósticos das estimações. Os 13 diagnósticos ativos foram aprovados, e as tabelas e figuras derivadas estão em `resultados/tabelas_finais/`.

## Reproducao

Abra o projeto `COVID_BMA.Rproj`, limpe o ambiente e execute `covid_bma.R` desde a primeira linha. O script reaproveita cadeias ja concluidas. Para refazer uma cadeia existente, defina a variavel de ambiente `COVID_BMA_REPROCESSAR=1` antes da execucao.

O modo reduzido de teste usa `COVID_BMA_MODO_TESTE=1` e grava em `resultados/teste`. Ele verifica o fluxo, mas seus coeficientes nao servem para o TCC.

## Pendencias deliberadamente adiadas

As sete pendencias de documentacao de fontes continuam registradas, mas nao bloqueiam a estimacao por decisao do autor. Elas deverao ser encerradas antes da auditoria bibliografica e da entrega.

## Análise dos resultados

A leitura técnica inicial está em `ANALISE_RESULTADOS_BMA.md`. A análise ativa compara o modelo principal, o ampliado, as escalas alternativas e a retirada de Fortaleza. Os 13 diagnósticos ativos estão aprovados.

## Análise descritiva

**Concluída e aprovada em 19 de agosto de 2026, após três rodadas de correção do Codex.** Script `analise_descritiva.R`, saídas em `resultados/analise_descritiva/`, leitura completa em `ANALISE_DESCRITIVA.md`. Estatísticas descritivas, matriz de correlação e heatmap, valores extremos (regra 1,5×IQR), influência de Fortaleza e mapas descritivos dos três desfechos, a partir de leitura e preparação autocontidas de `dadosv6.xlsx` (sem `source()` de `covid_bma.R`), conferidas contra os objetos BMA já aprovados em `resultados/estimacoes/principal/resultados.rds` — desfecho, nomes/ordem e valores das 35 covariáveis. Número de condição do desenho do modelo principal (35 covariáveis, todas padronizadas só para esse diagnóstico): **20,66**, sem comparação com a base antiga (840,6) por falta de garantia de metodologia idêntica. Correção de unidade fechada: `desp.saude` e `desp.educ` já estão em R$ por 100 mil habitantes (D05 do dicionário de dados fechada). Última correção: mapas exportados com fundo branco (estavam transparentes, ilegíveis em tema escuro).

## Diagnóstico de dependência espacial

**Concluído em 19 de agosto de 2026; revisado em 19 de agosto de 2026 após auditoria.** Script `diagnostico_espacial.R`, saídas em `resultados/diagnostico_espacial/`. I de Moran global sobre os resíduos model-averaged dos três modelos principais, malha do IBGE via `geobr` (ano 2020), vizinhança Queen (principal) e Rook (sensibilidade), 9.999 permutações, semente fixa. Resultado: dependência espacial residual significativa em casos e óbitos (pseudo-p = 0,0002, corrigido por contagem); letalidade sem significância a 5%, resultado limítrofe. A auditoria corrigiu o pseudo-valor-p bruto de `spdep::moran.mc()`, que retornava exatamente zero para casos e óbitos, e conteve a interpretação sobre a incerteza do BMA para não afirmar quantificação que o teste não sustenta. Detalhes e leitura completa em `ANALISE_RESULTADOS_BMA.md`. Esse achado deve ser registrado como limitação na redação dos resultados.

## Tabelas e gráficos finais dos resultados BMA

**Concluída e aprovada em 19 de agosto de 2026.** Script `tabelas_resultados.R`, saídas em `resultados/tabelas_finais/`, leitura completa em `TABELAS_RESULTADOS_FINAIS.md`. Reformata as tabelas técnicas já aprovadas para uso na redação: tabelas principais, resumos das sensibilidades, gráficos de PIP e quadro espacial. As variáveis fiscais aparecem no modelo ampliado; os gráficos distinguem PIP abaixo de 0,5 e identificam a cor como sinal posterior condicional. Não reestima nada.

## Manuscrito

**Fase 8 iniciada em 19 de agosto de 2026.** As Seções 3 e 4 do Google Doc `TCC v2` foram atualizadas. A metodologia registra 35 covariáveis no modelo principal, 37 no ampliado, `hyper=UIP`, duas cadeias nos modelos principal e ampliado, sensibilidades de cadeia única, transformações dos desfechos, exclusão da TMI, especificações de robustez e dependência espacial como limitação. A Seção 4 contém análise descritiva, resultados de casos, óbitos e letalidade, sensibilidades, modelo ampliado, diagnóstico espacial e discussão, com oito tabelas nativas e seis figuras provisórias. Backups nativos foram criados antes das alterações. Próximo passo: redigir a conclusão; depois revisar as seções anteriores, conferir as referências e normalizar o trabalho.

## Retomada em nova janela

O resumo operacional mais recente está em `C:/Users/dj blackops/Desktop/main/CONTEXTO_ATUAL_TCC.md`. O Google Doc ativo é `TCC v2`, ID `1SnXLRMrBX4KRXPQCQD4ZPpVTJEiPHeqGZHHZ231iZk4`. A pasta `outdated` é histórica e não deve ser atualizada nem usada como fonte do estado atual.
