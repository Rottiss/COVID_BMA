# Analise descritiva da base do TCC (Fase 4 do roadmap)
# Autocontido: le e prepara dadosv6.xlsx diretamente (mesmas variaveis,
# transformacoes e exclusoes de covid_bma.R, reescritas aqui em vez de
# reaproveitadas por source()), e confere o resultado contra os objetos BMA
# ja salvos em resultados/estimacoes/principal/resultados.rds via readRDS
# (leitura simples, sem reestimar nada). Nao executa covid_bma.R nem
# qualquer parte do fluxo de estimacao. Puramente descritivo.

pacotes_necessarios <- c(
  "readxl", "dplyr", "ggplot2", "corrplot", "reshape2", "scales",
  "sf", "geobr", "tidyr"
)
pacotes_ausentes <- pacotes_necessarios[
  !vapply(pacotes_necessarios, requireNamespace, logical(1), quietly = TRUE)
]
if (length(pacotes_ausentes) > 0L) {
  stop(
    "Instale os pacotes ausentes: ", paste(pacotes_ausentes, collapse = ", "),
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(ggplot2)
  library(corrplot)
  library(sf)
  library(geobr)
})

pasta_saida <- file.path("resultados", "analise_descritiva")
dir.create(pasta_saida, recursive = TRUE, showWarnings = FALSE)

log_linhas <- character(0)
registrar <- function(...) {
  linha <- paste0(...)
  log_linhas <<- c(log_linhas, linha)
  message(linha)
}

registrar("=== Analise descritiva (Fase 4) ===")
registrar("Data/hora: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"))

# 1. Leitura e preparacao autocontida da base --------------------------------
# Replica apenas os passos de leitura/validacao/transformacao de covid_bma.R
# (sem tocar na secao de estimacao). Mantido em sincronia manual com
# covid_bma.R; a secao 1b abaixo confere essa sincronia contra os objetos
# BMA ja aprovados, sem reestimar nada.

arquivo_dados <- "dadosv6.xlsx"
if (!file.exists(arquivo_dados)) {
  stop("dadosv6.xlsx nao encontrado na pasta do projeto.", call. = FALSE)
}

dados <- read_excel(arquivo_dados, sheet = "raw", na = c("", "NA"))
names(dados) <- trimws(names(dados))

if (nrow(dados) != 184L) {
  stop("Esperava 184 municipios; encontrados ", nrow(dados), ".", call. = FALSE)
}
if (anyNA(dados$codigo_ibge) || anyDuplicated(dados$codigo_ibge)) {
  stop("codigo_ibge deve estar preenchido e ser unico.", call. = FALSE)
}

dados <- dados |>
  mutate(
    log_casos100k = log(cov100k),
    log_obitos100k = log((obito + 0.5) / pop * 100000),
    logit_letal = log((obito + 0.5) / (covtotal - obito + 0.5)),
    energia100k = con.energia / pop * 100000
  )

padronizar <- function(x) as.numeric((x - mean(x)) / sd(x))

variaveis_binarias <- c("metrop", "semiarido", "aliadogov")

covariaveis_principais <- c(
  "pop", "area", "densidade", "pibpc", "idhm", "idm", "desp.saude",
  "desp.educ", "ideb5", "ideb9", "ideb3", "tax.agua", "energia100k",
  "tax.hom", "eleitas.fem", "bolsaf", "sus1k", "leitos1k", "prof1k",
  "metrop", "semiarido", "pop.rural", "aliadogov", "votos", "ivs.infra",
  "ivs.capital", "ivs.renda", "emprego", "ex.pobr", "imuni", "idosos",
  "int.circ", "int.resp", "int.diab", "int.asma"
)
covariaveis_fiscais <- c("recursofed", "auxem")
covariaveis_ampliadas <- c(covariaveis_principais, covariaveis_fiscais)
covariaveis_continuas <- setdiff(covariaveis_ampliadas, variaveis_binarias)

dados <- dados |>
  mutate(
    across(
      c(log_casos100k, log_obitos100k, logit_letal, all_of(covariaveis_continuas)),
      ~ padronizar(.x),
      .names = "z_{.col}"
    )
  )

nomes_para_modelo <- function(variaveis) {
  ifelse(variaveis %in% variaveis_binarias, variaveis, paste0("z_", variaveis))
}
covariaveis_principais_modelo <- nomes_para_modelo(covariaveis_principais)

dados_sem_fortaleza <- dados |> filter(codigo_ibge != 2304400)

registrar(
  "Base preparada: ", nrow(dados), " municipios, ",
  length(covariaveis_principais), " covariaveis principais, ",
  length(covariaveis_ampliadas), " covariaveis ampliadas."
)

# 1b. Conferencia contra os objetos BMA ja aprovados -------------------------
# So le o .rds (readRDS), nao executa covid_bma.R nem reestima nada. Confirma
# que esta preparacao independente bate com o X.data realmente usado no BMA.

caminho_resultados <- file.path("resultados", "estimacoes", "principal", "resultados.rds")
if (!file.exists(caminho_resultados)) {
  stop(
    "Nao encontrei ", caminho_resultados,
    ". Rode covid_bma.R antes deste script; este script nao reestima o BMA.",
    call. = FALSE
  )
}
objetos_principais <- readRDS(caminho_resultados)

conferencias <- list(
  casos = "z_log_casos100k",
  obitos = "z_log_obitos100k",
  letalidade = "z_logit_letal"
)
for (nome in names(conferencias)) {
  coluna_z <- conferencias[[nome]]
  x_data <- objetos_principais[[nome]][["cadeia_1"]]$arguments$X.data

  # (a) Desfecho: primeira coluna de X.data.
  diferenca_desfecho <- max(abs(x_data[[1]] - dados[[coluna_z]]))
  if (diferenca_desfecho > 1e-6) {
    stop(
      "Divergencia no desfecho entre a preparacao local e o X.data do BMA aprovado para ",
      nome, " (diferenca = ", diferenca_desfecho, "). Interrompendo.",
      call. = FALSE
    )
  }

  # (b) Covariaveis: nomes, ordem e valores das 35 colunas restantes.
  nomes_x_data <- colnames(x_data)[-1]
  if (!identical(nomes_x_data, covariaveis_principais_modelo)) {
    stop(
      "Divergencia nos nomes/ordem das covariaveis entre a preparacao local e o X.data ",
      "do BMA aprovado para ", nome, ". Esperado: ",
      paste(covariaveis_principais_modelo, collapse = ", "),
      ". Encontrado: ", paste(nomes_x_data, collapse = ", "),
      ". Interrompendo.",
      call. = FALSE
    )
  }
  matriz_x_data <- as.matrix(x_data[, -1, drop = FALSE])
  matriz_local <- as.matrix(dados[covariaveis_principais_modelo])
  diferenca_covariaveis <- max(abs(matriz_x_data - matriz_local))
  if (diferenca_covariaveis > 1e-6) {
    stop(
      "Divergencia nos valores das covariaveis entre a preparacao local e o X.data ",
      "do BMA aprovado para ", nome, " (diferenca maxima = ", diferenca_covariaveis,
      "). Interrompendo.",
      call. = FALSE
    )
  }
}
registrar(
  "Preparacao local conferida contra resultados/estimacoes/principal/resultados.rds: ",
  "desfecho, nomes/ordem das 35 covariaveis e valores das 35 covariaveis identicos ",
  "(diferenca < 1e-6) nos tres desfechos."
)

# 2. Unidades por variavel, conforme DICIONARIO_DADOS_FASE_1.md --------------

unidades <- c(
  cov100k = "casos por 100 mil habitantes",
  obito100k = "obitos por 100 mil habitantes",
  letal = "proporcao (obitos/casos)",
  pop = "habitantes",
  recursofed = "R$ declarados por 100 mil habitantes",
  auxem = "R$ declarados por 100 mil habitantes",
  area = "km2",
  densidade = "habitantes/km2",
  pibpc = "R$/habitante",
  idhm = "indice 0-1",
  idm = "indice IPECE",
  desp.saude = "R$ por 100 mil habitantes",
  desp.educ = "R$ por 100 mil habitantes",
  ideb5 = "indice IDEB",
  ideb9 = "indice IDEB",
  ideb3 = "indice IDEB",
  tax.agua = "percentual",
  con.energia = "MWh",
  energia100k = "MWh por 100 mil habitantes",
  tax.hom = "homicidios por 100 mil habitantes",
  eleitas.fem = "percentual",
  bolsaf = "percentual",
  sus1k = "unidades por mil habitantes",
  leitos1k = "leitos por mil habitantes",
  prof1k = "profissionais por mil habitantes",
  metrop = "indicador 0/1",
  semiarido = "indicador 0/1",
  pop.rural = "proporcao 0-1",
  aliadogov = "indicador 0/1",
  votos = "proporcao 0-1",
  ivs.infra = "indice 0-1",
  ivs.capital = "indice 0-1",
  ivs.renda = "indice 0-1",
  emprego = "proporcao 0-1",
  ex.pobr = "proporcao 0-1",
  # tmi fica registrada aqui so como referencia de unidade; nunca entra em
  # variaveis_descritivas porque a TMI foi excluida de todas as
  # especificacoes do modelo (ver covid_bma.R e ANALISE_RESULTADOS_BMA.md).
  tmi = "obitos < 1 ano por mil nascidos vivos",
  imuni = "proporcao (pode exceder 1; documentado como pendencia)",
  idosos = "proporcao 0-1",
  int.circ = "internacoes por 100 mil habitantes",
  int.resp = "internacoes por 100 mil habitantes",
  int.diab = "internacoes por 100 mil habitantes",
  int.asma = "internacoes por 100 mil habitantes"
)

# 3. Estatisticas descritivas -------------------------------------------------

variaveis_descritivas <- c("cov100k", "obito100k", "letal", covariaveis_ampliadas)
variaveis_descritivas <- unique(variaveis_descritivas)

descrever <- function(x) {
  data.frame(
    n = sum(!is.na(x)),
    n_ausentes = sum(is.na(x)),
    media = mean(x, na.rm = TRUE),
    desvio_padrao = sd(x, na.rm = TRUE),
    minimo = min(x, na.rm = TRUE),
    p25 = as.numeric(quantile(x, 0.25, na.rm = TRUE)),
    mediana = median(x, na.rm = TRUE),
    p75 = as.numeric(quantile(x, 0.75, na.rm = TRUE)),
    maximo = max(x, na.rm = TRUE)
  )
}

estatisticas_descritivas <- dplyr::bind_rows(
  lapply(variaveis_descritivas, function(v) {
    cbind(variavel = v, unidade = unidades[[v]], descrever(dados[[v]]))
  })
)

write.csv(
  estatisticas_descritivas,
  file.path(pasta_saida, "estatisticas_descritivas.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
registrar(
  "Estatisticas descritivas geradas para ", length(variaveis_descritivas),
  " variaveis (3 desfechos + ", length(covariaveis_ampliadas), " covariaveis)."
)

# 4. Valores extremos por variavel (regra do boxplot: 1.5 x IQR) -------------

detectar_outliers <- function(nome_variavel) {
  x <- dados[[nome_variavel]]
  q <- quantile(x, c(0.25, 0.75), na.rm = TRUE)
  iqr <- q[2] - q[1]
  limite_inferior <- q[1] - 1.5 * iqr
  limite_superior <- q[2] + 1.5 * iqr
  indices <- which(x < limite_inferior | x > limite_superior)
  if (length(indices) == 0L) {
    return(NULL)
  }
  data.frame(
    variavel = nome_variavel,
    municipio = dados$Municipios[indices],
    codigo_ibge = dados$codigo_ibge[indices],
    valor = x[indices]
  )
}

outliers_por_variavel <- dplyr::bind_rows(
  lapply(variaveis_descritivas, detectar_outliers)
)

write.csv(
  outliers_por_variavel,
  file.path(pasta_saida, "outliers_por_variavel.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)
registrar(
  "Valores extremos (regra 1.5xIQR) identificados: ", nrow(outliers_por_variavel),
  " observacoes em ", length(unique(outliers_por_variavel$variavel)), " variaveis."
)

# 5. Influencia de Fortaleza --------------------------------------------------
# Escore-z de Fortaleza em relacao aos demais 183 municipios, por variavel.

fortaleza_influencia <- dplyr::bind_rows(lapply(variaveis_descritivas, function(v) {
  x_resto <- dados_sem_fortaleza[[v]]
  x_fortaleza <- dados[[v]][dados$codigo_ibge == 2304400]
  media_resto <- mean(x_resto, na.rm = TRUE)
  desvio_resto <- sd(x_resto, na.rm = TRUE)
  escore_z <- if (desvio_resto > 0) (x_fortaleza - media_resto) / desvio_resto else NA_real_
  data.frame(
    variavel = v,
    valor_fortaleza = x_fortaleza,
    media_sem_fortaleza = media_resto,
    desvio_sem_fortaleza = desvio_resto,
    escore_z_fortaleza = escore_z
  )
})) |>
  dplyr::arrange(dplyr::desc(abs(escore_z_fortaleza)))

write.csv(
  fortaleza_influencia,
  file.path(pasta_saida, "fortaleza_influencia.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

variaveis_extremas_fortaleza <- fortaleza_influencia$variavel[
  !is.na(fortaleza_influencia$escore_z_fortaleza) &
    abs(fortaleza_influencia$escore_z_fortaleza) > 3
]
registrar(
  "Fortaleza fica a mais de 3 desvios-padrao dos demais municipios em: ",
  paste(variaveis_extremas_fortaleza, collapse = "; ")
)

# 6. Matriz de correlacao e heatmap ------------------------------------------
# A matriz de correlacao/heatmap inclui os tres desfechos padronizados junto
# com as covariaveis, por riqueza descritiva (mostra tambem a correlacao
# covariavel-desfecho). O numero de condicao, abaixo, usa uma matriz
# separada e mais estrita: SOMENTE as 35 covariaveis do modelo principal
# (covariaveis_principais_modelo), sem os desfechos, porque numero de
# condicao e uma propriedade do desenho X do modelo (as covariaveis), nao de
# X mais a variavel resposta.

colunas_matriz <- c(
  "z_log_casos100k", "z_log_obitos100k", "z_logit_letal",
  covariaveis_principais_modelo
)
matriz_dados <- as.matrix(dados[colunas_matriz])
matriz_correlacao <- cor(matriz_dados, use = "everything")

write.csv(
  as.data.frame(matriz_correlacao),
  file.path(pasta_saida, "matriz_correlacao.csv"),
  fileEncoding = "UTF-8"
)

# O desenho real do BMS mistura escalas: covariaveis continuas padronizadas
# (media 0, variancia 1) e os tres indicadores binarios na escala original
# 0/1. Numero de condicao e sensivel a escala, e os limiares de referencia de
# Belsley, Kuh e Welsch (1980) so valem se todas as colunas estiverem
# normalizadas de forma comparavel. Por isso, para ESTE diagnostico (nunca
# no desenho real do modelo, que permanece com as binarias na escala 0/1),
# padronizamos tambem os tres indicadores binarios antes de calcular kappa().
matriz_covariaveis <- as.matrix(dados[covariaveis_principais_modelo])
matriz_condicao <- matriz_covariaveis
for (variavel_binaria in variaveis_binarias) {
  matriz_condicao[, variavel_binaria] <- padronizar(matriz_condicao[, variavel_binaria])
}
numero_condicao <- kappa(matriz_condicao, exact = TRUE)
registrar(
  "Numero de condicao do desenho do modelo principal (35 covariaveis, todas ",
  "padronizadas -- inclusive as 3 binarias, so para este diagnostico -- sem ",
  "os desfechos e sem intercepto, pois o BMS trata o intercepto separadamente): ",
  format(numero_condicao, digits = 6),
  ". Belsley, Kuh e Welsch (1980) classificam numero de condicao acima de 30 ",
  "como atencao moderada e acima de 100 como severa, para matrizes com colunas ",
  "normalizadas como esta. Nao comparavel ao numero registrado no ROADMAP_TCC.md ",
  "para a base anterior a correcao, pois a composicao de variaveis e a ",
  "padronizacao usadas la nao estao documentadas neste projeto."
)

pares_alta_correlacao <- which(abs(matriz_correlacao) > 0.8 & upper.tri(matriz_correlacao), arr.ind = TRUE)
if (nrow(pares_alta_correlacao) > 0L) {
  tabela_pares <- data.frame(
    variavel_1 = rownames(matriz_correlacao)[pares_alta_correlacao[, 1]],
    variavel_2 = colnames(matriz_correlacao)[pares_alta_correlacao[, 2]],
    correlacao = matriz_correlacao[pares_alta_correlacao]
  ) |>
    dplyr::arrange(dplyr::desc(abs(correlacao)))
  write.csv(
    tabela_pares,
    file.path(pasta_saida, "pares_alta_correlacao.csv"),
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )
  registrar(
    "Pares com |correlacao| > 0.8: ", nrow(tabela_pares),
    ". Detalhes em pares_alta_correlacao.csv."
  )
} else {
  registrar("Nenhum par de variaveis com |correlacao| > 0.8.")
}

# Eixos numerados + matriz completa, sem reordenacao por cluster, inspirado
# na Figura S1 de Stojkoski et al. (2022, Artigo 1): eixos numericos evitam
# o texto diagonal apertado de 38 rotulos por extenso, e a ordem original
# (a mesma de "colunas_matriz" acima, nao hclust) preserva a leitura
# consistente com as demais tabelas do projeto. A legenda numero -> variavel
# fica numa tabela separada (legenda_heatmap_correlacao.csv).

nomes_correlacao <- c(
  log_casos100k = "Casos de COVID-19 por 100 mil habitantes (log)",
  log_obitos100k = "Óbitos de COVID-19 por 100 mil habitantes (log)",
  logit_letal = "Letalidade por COVID-19 (logit)",
  pop = "População estimada",
  area = "Área territorial",
  densidade = "Densidade demográfica",
  pibpc = "Produto Interno Bruto per capita",
  idhm = "Índice de Desenvolvimento Humano Municipal",
  idm = "Índice de Desenvolvimento Municipal",
  desp.saude = "Despesa municipal com saúde e saneamento",
  desp.educ = "Despesa municipal com educação e cultura",
  ideb5 = "IDEB dos anos iniciais do ensino fundamental",
  ideb9 = "IDEB dos anos finais do ensino fundamental",
  ideb3 = "IDEB do 3º ano do ensino médio",
  tax.agua = "Cobertura urbana de abastecimento de água",
  energia100k = "Consumo de energia elétrica por 100 mil habitantes",
  tax.hom = "Taxa de homicídios",
  eleitas.fem = "Proporção de mulheres eleitas",
  bolsaf = "População beneficiária do Programa Bolsa Família",
  sus1k = "Unidades de saúde vinculadas ao SUS",
  leitos1k = "Leitos vinculados ao SUS",
  prof1k = "Profissionais de saúde vinculados ao SUS",
  metrop = "Município integrante de região metropolitana",
  semiarido = "Município integrante do semiárido",
  pop.rural = "Proporção da população rural",
  aliadogov = "Alinhamento partidário do prefeito com o governo federal",
  votos = "Proporção de votos válidos do prefeito eleito",
  ivs.infra = "IVS Infraestrutura Urbana",
  ivs.capital = "IVS Capital Humano",
  ivs.renda = "IVS Renda e Trabalho",
  emprego = "Proporção da população em empregos formais",
  ex.pobr = "Proporção da população em extrema pobreza",
  imuni = "Cobertura média de imunização em menores de um ano",
  idosos = "Proporção da população com 60 anos ou mais",
  int.circ = "Internações por doenças do aparelho circulatório",
  int.resp = "Internações por doenças do aparelho respiratório",
  int.diab = "Internações por diabetes mellitus",
  int.asma = "Internações por asma"
)

codigos_sem_prefixo <- sub("^z_", "", colunas_matriz)
if (!all(codigos_sem_prefixo %in% names(nomes_correlacao))) {
  stop(
    "Variavel sem nome mapeado em nomes_correlacao: ",
    paste(setdiff(codigos_sem_prefixo, names(nomes_correlacao)), collapse = ", "),
    call. = FALSE
  )
}

legenda_heatmap <- data.frame(
  numero = seq_along(colunas_matriz),
  codigo = colunas_matriz,
  nome_variavel = unname(nomes_correlacao[codigos_sem_prefixo])
)
write.csv(
  legenda_heatmap,
  file.path(pasta_saida, "legenda_heatmap_correlacao.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)

matriz_numerada <- matriz_correlacao
rownames(matriz_numerada) <- colnames(matriz_numerada) <- as.character(legenda_heatmap$numero)

png(
  file.path(pasta_saida, "heatmap_correlacao.png"),
  width = 2200, height = 2200, res = 200
)
corrplot::corrplot(
  matriz_numerada,
  method = "color",
  type = "full",
  order = "original",
  tl.col = "black",
  tl.cex = 0.7,
  tl.srt = 0,
  cl.pos = "r",
  col = grDevices::colorRampPalette(
    c("#2166AC", "#67A9CF", "#D1E5F0", "#FEE090", "#FC8D59", "#B2182B")
  )(200),
  col.lim = c(-1, 1),
  diag = TRUE
)
dev.off()

# Legenda visual (imagem), preenchida por coluna (item 1 no topo da coluna 1,
# item 2 logo abaixo, etc.), no mesmo espirito da tabela de rotulos da Figura
# S1 de Stojkoski et al. -- para colar diretamente abaixo do heatmap no
# manuscrito. Usa graficos base (nao ggplot2) com strwidth() para medir a
# largura real de cada rotulo no dispositivo atual e evitar sobreposicao
# entre colunas -- unidades abstratas do ggplot nao garantiam isso.
n_colunas_legenda <- 3
n_linhas_legenda <- ceiling(nrow(legenda_heatmap) / n_colunas_legenda)
legenda_posicionada <- legenda_heatmap |>
  mutate(
    coluna = ceiling(numero / n_linhas_legenda),
    linha = numero - (coluna - 1) * n_linhas_legenda,
    rotulo = paste0(numero, ". ", nome_variavel)
  )

altura_legenda_px <- n_linhas_legenda * 42 + 40
espaco_entre_colunas <- 40
margem_esquerda <- 15
cex_legenda <- 0.95

# Passo 1 (medicao): como "user units" == pixels quando xlim cobre exatamente
# a largura do dispositivo em pixels, medimos a largura real de cada coluna
# num dispositivo temporario antes de saber a largura final necessaria --
# uma tentativa direta (largura fixa) cortava a ultima coluna.
arquivo_medicao <- tempfile(fileext = ".png")
png(arquivo_medicao, width = 3000, height = altura_legenda_px, res = 200)
par(mar = c(0, 0, 0, 0), family = "sans")
plot(
  NULL, xlim = c(0, 3000), ylim = c(0, altura_legenda_px),
  xaxs = "i", yaxs = "i", xaxt = "n", yaxt = "n", bty = "n", xlab = "", ylab = ""
)
larguras_coluna <- vapply(seq_len(n_colunas_legenda), function(c) {
  itens_coluna <- legenda_posicionada[legenda_posicionada$coluna == c, ]
  if (nrow(itens_coluna) == 0L) {
    return(0)
  }
  max(strwidth(itens_coluna$rotulo, cex = cex_legenda, units = "user"))
}, numeric(1))
dev.off()
unlink(arquivo_medicao)

largura_legenda_px <- margem_esquerda + sum(larguras_coluna) +
  espaco_entre_colunas * (n_colunas_legenda - 1) + margem_esquerda

# Passo 2 (desenho final), com a largura correta calculada acima.
png(
  file.path(pasta_saida, "legenda_heatmap_correlacao.png"),
  width = largura_legenda_px, height = altura_legenda_px, res = 200
)
par(mar = c(0, 0, 0, 0), family = "sans")
plot(
  NULL, xlim = c(0, largura_legenda_px), ylim = c(0, altura_legenda_px),
  xaxs = "i", yaxs = "i", xaxt = "n", yaxt = "n", bty = "n",
  xlab = "", ylab = ""
)
x_coluna <- margem_esquerda
for (c in seq_len(n_colunas_legenda)) {
  itens_coluna <- legenda_posicionada[legenda_posicionada$coluna == c, ]
  y_topo <- altura_legenda_px - 20
  passo_y <- 42
  text(
    x = x_coluna, y = y_topo - (itens_coluna$linha - 1) * passo_y,
    labels = itens_coluna$rotulo, adj = c(0, 1), cex = cex_legenda
  )
  x_coluna <- x_coluna + larguras_coluna[c] + espaco_entre_colunas
}
dev.off()

registrar(
  "Heatmap de correlacao salvo em heatmap_correlacao.png, com legenda numerica em ",
  "legenda_heatmap_correlacao.csv e legenda_heatmap_correlacao.png (",
  nrow(legenda_heatmap), " variaveis)."
)

# 7. Distribuicoes (boxplots facetados) --------------------------------------

covariaveis_continuas_plot <- setdiff(
  covariaveis_principais, c("metrop", "semiarido", "aliadogov")
)

dados_longos <- dados |>
  dplyr::select(dplyr::all_of(covariaveis_continuas_plot)) |>
  dplyr::mutate(dplyr::across(dplyr::everything(), as.numeric)) |>
  tidyr::pivot_longer(dplyr::everything(), names_to = "variavel", values_to = "valor")

grafico_distribuicoes <- ggplot(dados_longos, aes(x = variavel, y = valor)) +
  geom_boxplot(outlier.color = "#B2182B", outlier.size = 1, fill = "#DEEBF7") +
  facet_wrap(~variavel, scales = "free", ncol = 5) +
  theme_minimal(base_size = 8) +
  theme(
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    strip.text = element_text(size = 7)
  ) +
  labs(
    title = "Distribuição das covariáveis contínuas do modelo principal",
    x = NULL, y = NULL
  )

ggsave(
  file.path(pasta_saida, "distribuicoes_covariaveis.png"),
  grafico_distribuicoes,
  width = 14, height = 12, dpi = 150, bg = "white"
)
registrar("Boxplots de distribuicao salvos em distribuicoes_covariaveis.png.")

# 8. Mapas descritivos dos tres desfechos ------------------------------------
# Apenas descritivo: distribuicao geografica dos desfechos observados.
# Nao interpreta causalidade nem dependencia espacial (isso e tratado em
# diagnostico_espacial.R).

registrar("Baixando malha municipal do Ceara via geobr para os mapas...")
malha <- geobr::read_municipality(code_muni = "CE", year = 2020, showProgress = FALSE)
malha_dados <- malha |>
  dplyr::left_join(
    dados |> dplyr::select(codigo_ibge, cov100k, obito100k, letal),
    by = c("code_muni" = "codigo_ibge")
  )

if (anyNA(malha_dados$cov100k)) {
  stop("Falha ao associar todos os municipios da malha aos desfechos.", call. = FALSE)
}

mapear_desfecho <- function(variavel, titulo, arquivo, paleta = "OrRd") {
  cores_paleta <- RColorBrewer::brewer.pal(9, paleta)[2:9]
  grafico <- ggplot(malha_dados) +
    geom_sf(aes(fill = .data[[variavel]]), color = "grey35", linewidth = 0.15) +
    scale_fill_gradientn(colors = cores_paleta, name = NULL) +
    theme_void(base_size = 12) +
    theme(
      plot.background = element_rect(fill = "white", color = NA),
      plot.title = element_text(color = "black", face = "bold", size = 12, hjust = 0, margin = margin(t = 5, b = 5, l = 5)),
      plot.caption = element_text(color = "grey30", size = 9, hjust = 0.95, margin = margin(t = 5, b = 5)),
      legend.position = "right",
      legend.margin = margin(r = 10)
    ) +
    labs(title = titulo, caption = "Distribuição observada; sem interpretação causal.")
  ggsave(file.path(pasta_saida, arquivo), grafico, width = 8, height = 8, dpi = 200, bg = "white")
}

mapear_desfecho("cov100k", "Casos de COVID-19 por 100 mil habitantes (até 31/07/2020)", "mapa_casos100k.png")
mapear_desfecho("obito100k", "Óbitos por COVID-19 por 100 mil habitantes (até 31/07/2020)", "mapa_obitos100k.png", "PuRd")
mapear_desfecho("letal", "Letalidade por COVID-19 (óbitos/casos, até 31/07/2020)", "mapa_letalidade.png", "Purples")

registrar("Mapas descritivos dos tres desfechos salvos (mapa_casos100k.png, mapa_obitos100k.png, mapa_letalidade.png).")

# 9. Registros finais ----------------------------------------------------------

writeLines(log_linhas, file.path(pasta_saida, "log.txt"), useBytes = TRUE)
writeLines(capture.output(sessionInfo()), file.path(pasta_saida, "sessionInfo.txt"))

registrar("Analise descritiva concluida. Saidas em ", pasta_saida, ".")
