# Tabelas e gráficos finais dos resultados BMA

**Atualização:** 19 de agosto de 2026. **Concluída e aprovada após revisão metodológica e visual.**
**Script:** `tabelas_resultados.R`, saídas em `resultados/tabelas_finais/`.
**Escopo:** puramente formatação e apresentação. Não reestima nada — lê diretamente as tabelas técnicas já produzidas por `covid_bma.R` (modelos principal, ampliado e sensibilidades, todos aprovados) e por `diagnostico_espacial.R` (também aprovado), e as reformata: nomes de variáveis em português (a partir de `DICIONARIO_DADOS_FASE_1.md`), números arredondados, tabelas de comparação entre especificações e gráficos de PIP.

Material de apoio usado na redação da Seção 4 do manuscrito. As tabelas numéricas sustentam o texto; os gráficos permanecem provisórios e poderão ser refeitos na conversão para LaTeX.

## 1. Tabela principal por desfecho

`tabela_principal_casos.csv`, `tabela_principal_obitos.csv`, `tabela_principal_letalidade.csv` (e uma versão combinada, `tabela_principal_combinada.csv`): as 35 covariáveis do modelo principal, por desfecho, ordenadas por PIP decrescente, com nome em português, PIP, média posterior, desvio-padrão posterior, probabilidade de sinal positivo, direção (positiva/negativa, derivada de `Cond.Pos.Sign > 0,5`) e a marcação `PIP >= 0,5` já calculada em `covid_bma.R`.

Os seis achados mais estáveis de casos (IDM positivo; leitos, região metropolitana, internações circulatórias, IVS Renda e Trabalho e idosos negativos) e os quatro de letalidade (região metropolitana positiva; mulheres eleitas e imunização negativas; alinhamento político positivo) foram conferidos visualmente contra `ANALISE_RESULTADOS_BMA.md` e batem exatamente.

## 2. Resumo das sensibilidades

`resumo_sensibilidade_casos.csv`, `resumo_sensibilidade_obitos.csv`, `resumo_sensibilidade_letalidade.csv`: para cada covariável, o PIP na especificação principal, na ampliada, na(s) escala(s) alternativa(s) do desfecho (nível para casos e letalidade; nível e `log1p` para óbitos) e sem Fortaleza, mais uma contagem de quantas dessas especificações têm PIP ≥ 0,5. O cruzamento entre as tabelas de origem é sempre feito por código da variável (`variavel`) via `full_join` (união completa), nunca por posição ou ordem de linha, e nunca por `left_join` a partir do principal — a mesma regra que motivou boa parte da auditoria original da base. A união completa importa especialmente para `recursofed` e `auxem`: essas duas variáveis fiscais existem só no modelo ampliado (as demais especificações usam apenas as 35 covariáveis do modelo principal), então um `left_join` a partir do principal as descartaria silenciosamente. Com `full_join`, elas aparecem como linhas próprias, com `NA` nas colunas de especificações que não as incluem e o PIP correto na coluna `PIP_ampliado` — conferido contra `ANALISE_RESULTADOS_BMA.md`: 0,3549/0,3615 em casos, 0,1153/0,1075 em óbitos, 0,3785/0,3900 em letalidade, todos batendo.

## 3. Gráficos de PIP

`grafico_pip_casos.png`, `grafico_pip_obitos.png`, `grafico_pip_letalidade.png`: layout de três painéis (PIP, média posterior em valor absoluto, desvio-padrão posterior) para as 35 covariáveis do modelo principal, ordenadas por PIP. Redesenhado a partir de uma versão de barra única após comparação com a Figura 2 de Stojkoski et al. (2022, Artigo 1) — o padrão visual clássico de figura BMA usado nessa literatura. Barra sólida colorida quando PIP ≥ 0,5, barra vazada (contorno, sem preenchimento) quando PIP < 0,5; o sinal "+"/"−" ao lado da barra de PIP indica a direção (`Cond.Pos.Sign > 0,5`), em vez de usar cor para direção. Essa mudança também resolve o problema que o Codex tinha apontado na primeira versão (cor podendo ser lida como força de evidência): agora a cor de cada gráfico é única por desfecho, e a direção vem do sinal textual, não da cor.

Os três painéis usam escala logarítmica (base 10) no eixo horizontal, como na Figura 2 de Stojkoski et al. (2022) — sem essa escala, poucas covariáveis com valores altos de média posterior dominavam a faixa do eixo e a maioria das barras nesse painel ficava visualmente indistinguível de zero. A função `grafico_pip()` trata explicitamente o caso de valor não positivo antes de aplicar `scale_y_log10()`: qualquer valor ≤ 0 seria substituído por um piso de 1e-4 e geraria um aviso nomeando o arquivo afetado. Nos dados atuais dos três desfechos isso nunca ocorre (mínimo de PIP = 0,0907, de média posterior absoluta = 0,0001, de desvio-padrão posterior = 0,0216, todos em óbitos), então o piso é uma proteção defensiva, não a correção de um problema real na base.

**Correção de renderização (mesmo dia):** a primeira versão com escala log usava `geom_col()`, que desenha cada barra a partir de zero — mas `log10(0)` não é definido, e a combinação `geom_col() + scale_y_log10()` faz o ggplot2 renderizar o comprimento das barras de forma incorreta, sem relação com o valor real (em óbitos, por exemplo, a covariável de maior PIP, 0,9074, aparecia com a barra mais curta do painel, e covariáveis de PIP menor apareciam com barras quase do tamanho total do painel). Trocado por `geom_rect()` com `ymin`/`ymax` explícitos e finitos: cada barra é ancorada no menor valor do seu próprio painel (levemente abaixo dele), em vez de em zero. Como os dois limites da barra passam pela transformação logarítmica, o comprimento da barra volta a ser monotônico em relação ao valor dentro do painel — valor maior produz barra maior — sem ser proporcional ao valor na escala original, já que a posição em si é `log10(valor / base do painel)`. Reexecutado e conferido visualmente nos três gráficos. Essa relação vale dentro de cada painel individualmente: como as 35 covariáveis estão ordenadas por PIP (não por média posterior nem por desvio-padrão), apenas o painel de PIP tem a barra mais longa na primeira linha e decrescendo até a última — nos outros dois painéis a covariável com maior valor pode estar em qualquer linha (ex.: em casos, "Município integrante de região metropolitana" não é a primeira linha, mas tem a maior média posterior absoluta do painel).

## 4. Quadro do diagnóstico espacial

`quadro_diagnostico_espacial.csv`: reformatação de `resultados/diagnostico_espacial/tabela_moran.csv` com rótulos em português (`Casos`, `Óbitos`, `Letalidade` em vez dos códigos internos) e o texto de conclusão com acentuação correta. Nenhum valor numérico foi recalculado — é a mesma tabela aprovada no diagnóstico espacial, apenas reformatada para o texto.

## Limites

Este material não substitui a leitura técnica completa em `ANALISE_RESULTADOS_BMA.md` — inclusive a seção "Dependência espacial dos resíduos", que documenta o diagnóstico gerado por `diagnostico_espacial.R`. As tabelas e gráficos aqui são a mesma informação já aprovada, apenas reorganizada para uso direto na redação.

## Uso no manuscrito

Em 19/08/2026, os três gráficos de BMA foram inseridos provisoriamente no Google Doc `TCC v2`, junto aos três mapas descritivos. A Seção 4 também recebeu oito tabelas nativas construídas a partir das saídas aprovadas. A próxima etapa do manuscrito é a conclusão; a composição final das figuras será revista na passagem para LaTeX.
