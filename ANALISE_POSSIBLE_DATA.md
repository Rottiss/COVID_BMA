# Análise dos arquivos da pasta `possible data`

**Data:** 18 de agosto de 2026  
**Arquivos examinados:** 15  
**Procedimento:** inspeção de estrutura, período, cobertura municipal, instituição registrada e comparação com `COVID_BMA/dadosv6.xlsx`.

Nenhum arquivo da pasta foi alterado. A comparação foi feita por nome municipal normalizado. Os arquivos que já contêm código IBGE serão usados dessa forma na reconstrução.

## Resultado geral

Sete arquivos têm utilidade direta para a fase 1 ou para a reconstrução da base: `aguaporcento.xlsx`, `bolsafamilia.xlsx`, `generoeleicoes.csv`, `susmilhabitante.xlsx`, `Tabela 1.4.1 (Planilha)_data.csv`, `taxahomi.ods` e `despesaeducultipea.xls`.

Cinco arquivos ajudam a documentar a história da base ou a validar variáveis já conhecidas: `2Indicador.xlsx`, `DADOSGERAIS.xlsx`, `IDHM2010.xlsx`, `IDM2018.xlsx` e `transferencias_coronavirusmaio.csv`.

Dois arquivos são redundantes ou servem apenas como alternativa temporal: `Indicador.xlsx` e `Tabela 15.1.4 (Planilha).xlsx`. `CE_Ceara_GeralUF.xls` não serve para o modelo municipal atual porque contém dados estaduais, em sua maior parte de 2008 e 2009.

## Avaliação por arquivo

| Arquivo | Conteúdo identificado | Utilidade | Decisão |
|---|---|---|---|
| `aguaporcento.xlsx` | Cobertura urbana e rural de abastecimento de água em 2019 | Os 184 valores urbanos coincidem com `tax.agua`. O arquivo fixa ano, universo urbano e escala percentual. | Incorporar como fonte local de reconstrução de `tax.agua`; buscar a referência bibliográfica ou URL oficial do IPECE para a citação final. |
| `bolsafamilia.xlsx` | Percentual de famílias do Cadastro Único e percentual de pessoas beneficiárias do PBF em 2020 | A coluna de pessoas beneficiárias coincide nos 184 municípios e registra o Ministério da Cidadania e a Secretaria Nacional de Renda e Cidadania. | Incorporar. O mês de referência ainda não aparece no arquivo e continua pendente. |
| `generoeleicoes.csv` | Quantidade e percentual de eleitas do sexo feminino | Os percentuais coincidem nos 184 municípios. O arquivo também preserva o numerador feminino. | Incorporar como planilha intermediária. Ainda falta documentar cargo, denominador, eleição de referência e extração original do TSE. |
| `susmilhabitante.xlsx` | Leitos, profissionais e unidades de saúde por mil habitantes em 2019; fonte SESA | `leitos1k` e `prof1k` coincidem nos 184 municípios. `sus1k` coincide nos 184 após arredondamento para duas casas decimais. | Incorporar. Este arquivo resolve o ano e a instituição de `sus1k`, que antes estavam sem comprovação local. As três taxas deverão ser recalculadas com a população corrigida. |
| `Tabela 1.4.1  (Planilha)_data.csv` | Indicador municipal de pertencimento ao semiárido | Os 184 indicadores coincidem com `semiarido`. O arquivo contém colunas auxiliares de uma conciliação anterior. | Incorporar como lista de conferência. Ainda falta identificar a edição do anuário, a norma territorial e o ano da delimitação. |
| `taxahomi.ods` | Taxa de homicídios de 2019 para todos os municípios brasileiros, com código IBGE; segunda aba com recorte do Ceará | É a melhor fonte local para reconstruir `tax.hom` por código. A primeira aba contém 5.561 registros municipais e a segunda, 184 municípios cearenses. | Incorporar. Preservar a primeira aba como autoridade do arquivo e ignorar a segunda como fonte independente, pois ela é um recorte intermediário. |
| `despesaeducultipea.xls` | Despesa municipal em educação e cultura, em reais, em 2018 | Contém os 184 municípios e descreve a série como STN, código DFEDUCM. Confirma que os valores armazenados são absolutos, não taxas por 100 mil habitantes. | Incorporar para reconstruir `desp.educ`. A decisão entre valor absoluto, per capita ou por 100 mil no modelo permanece aberta. |
| `2Indicador.xlsx` | População total, urbana e rural do Censo de 2010; proporção rural calculada | A proporção coincide nos 184 municípios com `pop.rural`. | Manter como planilha intermediária de conferência. Na reconstrução, preferir tabela oficial com código IBGE. |
| `DADOSGERAIS.xlsx` | Versão antiga da base, com corte de COVID em 31/05/2020 e 24 variáveis | Explica a origem de várias colunas e confirma que a base atual herdou água, homicídios, gênero, PBF e indicadores do SUS. O IDEB dos anos finais difere em 19 municípios, o mesmo problema já identificado. | Manter como registro histórico. Não usar como fonte final nem misturar seu corte epidemiológico com 31/07/2020. |
| `IDHM2010.xlsx` | IDHM municipal de 2010 | Útil para reconstruir e conferir `idhm`, que já foi marcado para correção por desalinhamento. | Incorporar como fonte local, de preferência depois de acrescentar código IBGE por tabela de correspondência. |
| `IDM2018.xlsx` | IDM global, ranking e quatro dimensões em 2018 | Confirma a variável `idm` e oferece os componentes do índice. | Manter como fonte de `idm`; os componentes não entram no modelo sem nova decisão de especificação. |
| `transferencias_coronavirusmaio.csv` | Valores transferidos aos municípios em um recorte identificado no nome como “maio” | Não coincide com `recursofed`: zero coincidências em 183 municípios e correlação de 0,0028. Os valores aparecem na base antiga `DADOSGERAIS.xlsx`, cujo rótulo menciona abril e maio. | Preservar como evidência de uma construção antiga. Não usar na base atual até que o período e o significado do valor sejam confirmados. |
| `Indicador.xlsx` | Percentual de pessoas beneficiárias do PBF em 2020 | Os 184 valores coincidem, mas o arquivo contém menos metadados que `bolsafamilia.xlsx`. | Redundante. Usar `bolsafamilia.xlsx` como arquivo principal. |
| `Tabela 15.1.4 (Planilha).xlsx` | Cobertura urbana e rural de água em 2020 | Apenas 5 dos 184 valores urbanos são iguais aos de 2019. A diferença absoluta média é 0,8124 ponto percentual. | Não substituir `tax.agua`, que usa 2019. Guardar para análise de sensibilidade temporal, se necessário. |
| `CE_Ceara_GeralUF.xls` | Caderno de Informações de Saúde do Ceará, com dados estaduais de 2008 e 2009 | Não contém a estrutura municipal necessária ao modelo de 184 municípios e está fora do período principal. | Não incorporar à base. Pode servir apenas como contexto histórico estadual, caso haja uma justificativa específica no texto. |

## Alterações na situação das variáveis

`tax.agua` passa de “Verificar” para “Confirmada”. O arquivo de 2019 cobre todos os municípios e reproduz a coluna atual.

`sus1k` também passa para “Confirmada”. `susmilhabitante.xlsx` identifica SESA, 2019, cobre os 184 municípios e reproduz os valores depois do arredondamento usado na base.

`bolsaf`, `eleitas.fem` e `semiarido` tiveram seus valores municipais confirmados, mas permanecem em “Verificar”. Ainda faltam, respectivamente, o mês do PBF; cargo, denominador e referência eleitoral; e norma, edição e ano da delimitação territorial.

`desp.educ` continua em “Decidir”. O arquivo novo resolve a fonte e a unidade original, mas não decide qual transformação deve entrar no modelo.

## Arquivos prioritários para a fase 2

Na reconstrução por código IBGE, a ordem de aproveitamento recomendada é:

1. `taxahomi.ods`, usando código IBGE e a aba nacional;
2. `aguaporcento.xlsx` para a cobertura urbana de água em 2019;
3. `susmilhabitante.xlsx`, com recálculo das três taxas após corrigir a população;
4. `despesaeducultipea.xls` para a despesa absoluta de educação e cultura;
5. `IDHM2010.xlsx` e `IDM2018.xlsx`;
6. `bolsafamilia.xlsx`, `generoeleicoes.csv` e a tabela do semiárido depois de completar os metadados pendentes.

Os arquivos devem permanecer na pasta `possible data` até que sejam copiados para uma estrutura definitiva de fontes. Nenhum deles deve substituir diretamente `dadosv6.xlsx`.
