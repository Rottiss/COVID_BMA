# Análise técnica dos resultados BMA

**Atualização:** 19 de agosto de 2026  
**Estado:** 13 diagnósticos ativos aprovados; interpretação técnica inicial.

## Critério de leitura

A análise usa `PIP >= 0,5` como regra operacional de inclusão. O limiar não transforma associações em efeitos causais e não deve ser lido como teste de significância. A direção é dada pela média posterior e pela probabilidade condicional de sinal positivo.

As covariáveis contínuas foram padronizadas. Os indicadores binários não foram padronizados. Por isso, a magnitude de um coeficiente binário não deve ser comparada diretamente com a magnitude de uma covariável contínua.

## Casos por 100 mil habitantes

Seis covariáveis permaneceram acima de 0,5 em todas as especificações comparadas:

| Covariável | PIP principal | PIP ampliado | Direção |
|---|---:|---:|---|
| Índice de Desenvolvimento Municipal | 0,9965 | 0,9960 | positiva |
| Leitos por mil habitantes | 0,9888 | 0,9769 | negativa |
| Região metropolitana | 0,9807 | 0,9702 | negativa |
| Internações por doenças circulatórias | 0,7572 | 0,7390 | negativa |
| IVS Renda e Trabalho | 0,7337 | 0,6490 | negativa |
| Proporção de idosos | 0,6988 | 0,7287 | negativa |

Esses seis resultados também permaneceram acima de 0,5 com casos em nível e sem Fortaleza. As direções não mudaram.

Bolsa Família e internações por asma ficaram acima de 0,5 em cinco das seis especificações, mas perderam suporte quando os casos foram usados em nível. Taxa de homicídios, IDEB, semiárido, cobertura de água e unidades do SUS ficaram próximos do limiar e dependem da especificação.

Os sinais negativos não significam proteção causal. Eles podem refletir diferenças de testagem, notificação, momento de entrada da epidemia, estrutura urbana ou correlação entre indicadores municipais.

## Óbitos por 100 mil habitantes

No modelo principal, três covariáveis ficaram acima de 0,5:

| Covariável | PIP principal | PIP ampliado | Direção |
|---|---:|---:|---|
| Índice de Desenvolvimento Municipal | 0,9074 | 0,9114 | positiva |
| Leitos por mil habitantes | 0,6198 | 0,5994 | negativa |
| Proporção de idosos | 0,5310 | 0,5420 | negativa |

A retirada de Fortaleza preservou os três resultados. O modelo ampliado também produziu poucas mudanças.

O resultado de leitos é sensível à transformação do desfecho: sua PIP caiu para 0,316 no nível de óbitos por 100 mil e subiu para 0,889 com `log1p`. A direção foi negativa nas especificações em que a variável recebeu maior PIP.

## Letalidade

Região metropolitana, mulheres eleitas, imunização e alinhamento do prefeito com o governo federal permaneceram acima de 0,5 nas quatro famílias de especificações ativas. Suas direções foram, respectivamente, positiva, negativa, negativa e positiva.

A associação da região metropolitana foi positiva:

| Especificação | PIP |
|---|---:|
| Principal | 0,7809 |
| Ampliada | 0,7316 |
| Letalidade em nível | 0,7060 |
| Sem Fortaleza | 0,6490 |

IDEB do 9º ano apresentou direção negativa e PIP entre 0,405 e 0,566. IVS Capital Humano apresentou direção positiva e PIP entre 0,369 e 0,578. Esses resultados são intermediários, não invariantes.

Leitos por mil habitantes não é um resultado estável para letalidade. A PIP foi 0,564 no principal, 0,500 no ampliado e 0,374 na letalidade em nível. Na escala em nível, o sinal ficou indeterminado.

## Modelo ampliado

Transferências federais e auxílio emergencial ficaram abaixo de 0,5 nos três desfechos:

| Desfecho | PIP de transferências | PIP de auxílio |
|---|---:|---:|
| Casos | 0,3549 | 0,3615 |
| Óbitos | 0,1153 | 0,1075 |
| Letalidade | 0,3785 | 0,3900 |

A entrada das variáveis fiscais reduziu alguns PIPs próximos de 0,5, mas preservou as covariáveis com maior suporte. Não há base para apresentar transferências ou auxílio como correlatos selecionados pelo critério operacional.

## Classificação para o texto

### Achados com maior estabilidade

- Casos: IDM positivo; leitos, região metropolitana, internações circulatórias, IVS Renda e Trabalho e idosos com direção negativa.
- Óbitos: IDM positivo. Leitos e idosos aparecem no modelo central, mas exigem ressalva sobre a escala do desfecho.
- Letalidade: região metropolitana positiva; mulheres eleitas e imunização negativas; alinhamento político positivo.

### Achados dependentes da especificação

- Casos: Bolsa Família, asma, homicídios, IDEB, semiárido, água e unidades do SUS.
- Óbitos: leitos e idosos.
- Letalidade: IDEB do 9º ano, IVS Capital Humano, leitos, extrema pobreza, internações respiratórias, unidades do SUS e Bolsa Família.

### Variáveis sem suporte pelo limiar

- transferências federais;
- auxílio emergencial.

## Dependência espacial dos resíduos

**Atualização:** 19 de agosto de 2026.

Os resíduos model-averaged dos três modelos principais foram testados com o I de Moran global sobre a malha municipal do IBGE (via `geobr`, ano 2020), vizinhança Queen como especificação principal e Rook como sensibilidade, teste por permutação com 9.999 réplicas, semente fixa e hipótese bilateral. Nenhum dos 184 municípios ficou sem vizinho de primeira ordem em nenhuma das duas matrizes. Script, log de correspondência, resíduos, objetos de vizinhança e `sessionInfo()` estão em `resultados/diagnostico_espacial/`.

O `spdep::moran.mc()` bruto retornou pseudo-valor-p igual a zero para casos e óbitos, o que não é um resultado válido para um teste de Monte Carlo por permutação. A tabela abaixo usa o pseudo-valor-p recalculado pela correção de contagem (Davison; Hinkley, 1997): `p = (1 + contagem de permutações tão ou mais extremas) / (permutações + 1)`, bilateral. Com 9.999 permutações, o menor pseudo-valor-p bilateral atingível é 2/10.000 = 0,0002. Os dois valores (corrigido e bruto de `spdep`) ficam registrados em `resultados/diagnostico_espacial/tabela_moran.csv`.

| Desfecho | I de Moran (Queen) | Pseudo-p (Queen) | I de Moran (Rook) | Pseudo-p (Rook) | Conclusão |
|---|---:|---:|---:|---:|---|
| Casos | 0,2560 | 0,0002 | 0,2605 | 0,0002 | dependência espacial residual |
| Óbitos | 0,2251 | 0,0002 | 0,2442 | 0,0002 | dependência espacial residual |
| Letalidade | 0,0845 | 0,0602 | 0,0921 | 0,0536 | sem significância a 5%, resultado limítrofe |

Casos e óbitos apresentam autocorrelação espacial positiva e estatisticamente significativa nos resíduos do modelo principal. Isso indica que municípios geograficamente próximos tendem a ter resíduos semelhantes, o que questiona a adequação da suposição de observações aproximadamente independentes usada para interpretar a incerteza das PIPs. O teste de Moran confirma a autocorrelação residual, mas não quantifica o quanto ela afeta a incerteza reportada pelo BMA; a dependência espacial deve ser registrada como um limite de inferência do estudo, não como uma medida de quanto a incerteza está subestimada. Letalidade não apresentou significância a 5% em nenhuma das duas matrizes, embora o resultado seja limítrofe e não deva ser lido como prova de independência espacial.

## Limites para a redação

Os resultados são associações ecológicas entre municípios. Não sustentam afirmações de causalidade. Direções contraintuitivas devem ser discutidas junto a subnotificação, capacidade de testagem, diferenças temporais da epidemia e correlação entre indicadores.

A dependência espacial dos resíduos de casos e óbitos, descrita acima, deve ser discutida explicitamente como limitação. Para letalidade, o resultado limítrofe não permite afirmar que a dependência geográfica foi descartada.

A TMI foi excluída de todas as especificações por decisão metodológica. As saídas antigas que a incluem são históricas e não devem ser usadas nas tabelas, na interpretação ou no manuscrito.
