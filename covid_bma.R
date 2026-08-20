# Preparacao dos dados para os modelos BMA do TCC
# Base municipal do Ceara, com desfechos acumulados ate 31/07/2020

pacotes_necessarios <- c("readxl", "dplyr", "BMS")
pacotes_ausentes <- pacotes_necessarios[
  !vapply(pacotes_necessarios, requireNamespace, logical(1), quietly = TRUE)
]

if (length(pacotes_ausentes) > 0L) {
  stop(
    "Instale os pacotes ausentes: ",
    paste(pacotes_ausentes, collapse = ", "),
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(BMS)
})

# 1. Leitura da base -------------------------------------------------------

arquivo_dados <- "dadosv6.xlsx"

if (!file.exists(arquivo_dados)) {
  stop(
    "O arquivo dadosv6.xlsx nao foi encontrado na pasta do projeto.",
    call. = FALSE
  )
}

dados <- read_excel(
  path = arquivo_dados,
  sheet = "raw",
  na = c("", "NA")
)

# O cabecalho da coluna de populacao possui um espaco no arquivo original.
names(dados) <- trimws(names(dados))

colunas_obrigatorias <- c(
  "Municipios", "codigo_ibge", "covtotal", "cov100k", "obito",
  "obito100k", "letal", "pop", "recursofed", "auxem", "area",
  "densidade", "pibpc", "idhm", "idm", "desp.saude", "desp.educ",
  "ideb5", "ideb9", "ideb3", "tax.agua", "con.energia", "tax.hom",
  "eleitas.fem", "bolsaf", "sus1k", "leitos1k", "prof1k", "metrop",
  "semiarido", "pop.rural", "aliadogov", "votos", "ivs", "ivs.infra",
  "ivs.capital", "ivs.renda", "emprego", "ex.pobr", "tmi", "imuni",
  "idosos", "int.circ", "int.resp", "int.diab", "int.asma"
)

colunas_ausentes <- setdiff(colunas_obrigatorias, names(dados))

if (length(colunas_ausentes) > 0L) {
  stop(
    "A planilha nao contem as colunas obrigatorias: ",
    paste(colunas_ausentes, collapse = ", "),
    call. = FALSE
  )
}

colunas_numericas <- setdiff(colunas_obrigatorias, "Municipios")

dados <- dados |>
  mutate(across(all_of(colunas_numericas), as.numeric))

# 2. Validacao da base -----------------------------------------------------

if (nrow(dados) != 184L) {
  stop(
    "A base deve conter 184 municipios; foram encontrados ",
    nrow(dados),
    ".",
    call. = FALSE
  )
}

if (anyNA(dados$codigo_ibge) || anyDuplicated(dados$codigo_ibge)) {
  stop(
    "Os codigos IBGE devem estar preenchidos e ser unicos.",
    call. = FALSE
  )
}

if (anyNA(dados$Municipios) || anyDuplicated(dados$Municipios)) {
  stop(
    "Os nomes dos municipios devem estar preenchidos e ser unicos.",
    call. = FALSE
  )
}

if (anyNA(dados$pop) || any(dados$pop <= 0)) {
  stop(
    "A populacao deve estar preenchida e ser positiva.",
    call. = FALSE
  )
}

if (anyNA(dados$covtotal) || any(dados$covtotal <= 0)) {
  stop(
    "Os casos acumulados devem estar preenchidos e ser positivos.",
    call. = FALSE
  )
}

if (anyNA(dados$obito) || any(dados$obito < 0)) {
  stop(
    "Os obitos devem estar preenchidos e nao podem ser negativos.",
    call. = FALSE
  )
}

if (any(dados$obito > dados$covtotal)) {
  stop(
    "Ha municipio com mais obitos do que casos confirmados.",
    call. = FALSE
  )
}

validar_calculo <- function(observado, esperado, nome, tolerancia = 1e-7) {
  erro <- abs(observado - esperado)
  limite <- tolerancia * pmax(1, abs(esperado))

  if (anyNA(erro) || any(erro > limite)) {
    stop(
      "A coluna ", nome, " nao confere com os dados de origem.",
      call. = FALSE
    )
  }
}

validar_calculo(
  observado = dados$cov100k,
  esperado = dados$covtotal / dados$pop * 100000,
  nome = "cov100k"
)

validar_calculo(
  observado = dados$obito100k,
  esperado = dados$obito / dados$pop * 100000,
  nome = "obito100k"
)

validar_calculo(
  observado = dados$letal,
  esperado = dados$obito / dados$covtotal,
  nome = "letal"
)

variaveis_binarias <- c("metrop", "semiarido", "aliadogov")

for (variavel in variaveis_binarias) {
  valor <- dados[[variavel]]
  invalido <- !is.na(valor) & !(valor %in% c(0, 1))

  if (any(invalido)) {
    stop(
      "A variavel binaria ", variavel,
      " contem valor diferente de 0 ou 1.",
      call. = FALSE
    )
  }
}

# 3. Transformacao dos desfechos e da energia -----------------------------

dados <- dados |>
  mutate(
    log_casos100k = log(cov100k),
    log_obitos100k = log((obito + 0.5) / pop * 100000),
    logit_letal = log(
      (obito + 0.5) /
        (covtotal - obito + 0.5)
    ),
    log1p_obitos100k = log1p(obito100k),
    energia100k = con.energia / pop * 100000
  )

if (anyNA(dados$energia100k) || any(dados$energia100k <= 0)) {
  stop(
    "O consumo de energia por 100 mil habitantes deve ser positivo.",
    call. = FALSE
  )
}

padronizar <- function(x, nome) {
  if (anyNA(x)) {
    stop(
      "A variavel ", nome, " contem valores ausentes.",
      call. = FALSE
    )
  }

  desvio <- sd(x)

  if (!is.finite(desvio) || desvio == 0) {
    stop(
      "A variavel ", nome, " nao pode ser padronizada.",
      call. = FALSE
    )
  }

  as.numeric((x - mean(x)) / desvio)
}

desfechos_principais <- c(
  casos = "log_casos100k",
  obitos = "log_obitos100k",
  letalidade = "logit_letal"
)

dados <- dados |>
  mutate(
    across(
      all_of(unname(desfechos_principais)),
      ~ padronizar(.x, cur_column()),
      .names = "z_{.col}"
    )
  )

# 4. Covariaveis dos modelos ----------------------------------------------

# O IVS agregado nao entra nos modelos. A TMI e preservada na leitura da
# base, mas foi excluida de todas as especificacoes.
# As variaveis fiscais entram somente no modelo ampliado.
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

faltantes_por_variavel <- colSums(is.na(dados[covariaveis_ampliadas]))
faltantes_por_variavel <- faltantes_por_variavel[faltantes_por_variavel > 0L]

if (length(faltantes_por_variavel) > 0L) {
  stop(
    "As covariaveis dos modelos contem NA: ",
    paste(names(faltantes_por_variavel), collapse = ", "),
    call. = FALSE
  )
}

dados <- dados |>
  mutate(
    across(
      all_of(covariaveis_continuas),
      ~ padronizar(.x, cur_column()),
      .names = "z_{.col}"
    )
  )

nomes_para_modelo <- function(variaveis) {
  ifelse(
    variaveis %in% variaveis_binarias,
    variaveis,
    paste0("z_", variaveis)
  )
}

covariaveis_principais_modelo <- nomes_para_modelo(covariaveis_principais)
covariaveis_ampliadas_modelo <- nomes_para_modelo(covariaveis_ampliadas)

# 5. Preparacao dos objetos usados pelo BMS -------------------------------

montar_dados_bms <- function(base, desfecho, covariaveis) {
  dados_bms <- base |>
    select(all_of(c(desfecho, covariaveis)))

  if (anyNA(dados_bms)) {
    stop(
      "O conjunto preparado para o BMS contem valores ausentes.",
      call. = FALSE
    )
  }

  if (any(!is.finite(as.matrix(dados_bms)))) {
    stop(
      "O conjunto preparado para o BMS contem valor infinito ou nao numerico.",
      call. = FALSE
    )
  }

  dados_bms
}

preparar_modelos <- function(base, desfechos, covariaveis) {
  modelos <- lapply(
    unname(desfechos),
    function(desfecho) {
      montar_dados_bms(
        base = base,
        desfecho = paste0("z_", desfecho),
        covariaveis = covariaveis
      )
    }
  )

  names(modelos) <- names(desfechos)
  modelos
}

# Em cada objeto, a primeira coluna e o desfecho e as demais sao covariaveis.
modelos_principais <- preparar_modelos(
  base = dados,
  desfechos = desfechos_principais,
  covariaveis = covariaveis_principais_modelo
)

modelos_ampliados <- preparar_modelos(
  base = dados,
  desfechos = desfechos_principais,
  covariaveis = covariaveis_ampliadas_modelo
)

# 6. Analises de sensibilidade --------------------------------------------

# Escalas alternativas dos tres desfechos.
dados <- dados |>
  mutate(
    z_casos100k_nivel = padronizar(cov100k, "cov100k"),
    z_obitos100k_nivel = padronizar(obito100k, "obito100k"),
    z_log1p_obitos100k = padronizar(log1p_obitos100k, "log1p_obitos100k"),
    z_letal_nivel = padronizar(letal, "letal")
  )

desfechos_sensibilidade <- c(
  casos_nivel = "z_casos100k_nivel",
  obitos_nivel = "z_obitos100k_nivel",
  obitos_log1p = "z_log1p_obitos100k",
  letalidade_nivel = "z_letal_nivel"
)

modelos_sensibilidade_escala <- lapply(
  desfechos_sensibilidade,
  function(desfecho) {
    montar_dados_bms(
      base = dados,
      desfecho = desfecho,
      covariaveis = covariaveis_principais_modelo
    )
  }
)

# Fortaleza e retirada pelo codigo IBGE, que nao depende da grafia do nome.
dados_sem_fortaleza <- dados |>
  filter(codigo_ibge != 2304400)

modelos_sem_fortaleza <- preparar_modelos(
  base = dados_sem_fortaleza,
  desfechos = desfechos_principais,
  covariaveis = covariaveis_principais_modelo
)

cat(
  "Preparacao concluida.\n",
  "Municipios no modelo principal:", nrow(dados), "\n",
  "Covariaveis no modelo principal:", length(covariaveis_principais), "\n",
  "Covariaveis no modelo ampliado:", length(covariaveis_ampliadas), "\n"
)

# 7. Configuracao das estimacoes ------------------------------------------

modo_teste <- identical(Sys.getenv("COVID_BMA_MODO_TESTE"), "1")
reprocessar_existentes <- identical(Sys.getenv("COVID_BMA_REPROCESSAR"), "1")

configuracao_principal <- list(
  burn = if (modo_teste) 100 else 200000,
  iter = if (modo_teste) 500 else 1000000,
  nmodel = if (modo_teste) 100 else 2000,
  mcmc = "bd",
  g = "hyper=UIP",
  mprior = "random",
  force.full.ols = TRUE
)

configuracao_sensibilidade <- configuracao_principal
configuracao_sensibilidade$burn <- if (modo_teste) 100 else 100000
configuracao_sensibilidade$iter <- if (modo_teste) 500 else 500000

sementes_principais <- c(20200731, 20200801)
sementes_sensibilidade <- 20200731

pasta_raiz_resultados <- file.path(
  "resultados",
  if (modo_teste) "teste" else "estimacoes"
)
dir.create(pasta_raiz_resultados, recursive = TRUE, showWarnings = FALSE)
estimar_cadeias <- function(dados_modelo, pasta, configuracao, sementes) {
  dir.create(pasta, recursive = TRUE, showWarnings = FALSE)
  numero_covariaveis <- ncol(dados_modelo) - 1L
  cadeias <- vector("list", length(sementes))
  names(cadeias) <- paste0("cadeia_", seq_along(sementes))
  valores_iniciais <- rep(list(NA), length(sementes))
  if (length(sementes) > 1L) {
    valores_iniciais[[2]] <- 0
  }

  for (i in seq_along(sementes)) {
    arquivo <- file.path(pasta, paste0("cadeia_", i, ".rds"))

    if (file.exists(arquivo) && !reprocessar_existentes) {
      message("Carregando resultado existente: ", arquivo)
      cadeias[[i]] <- readRDS(arquivo)
      next
    }

    set.seed(sementes[i])
    message(
      "Estimando ", basename(pasta), ", cadeia ", i,
      " de ", length(sementes), "."
    )

    cadeias[[i]] <- BMS::bms(
      X.data = dados_modelo,
      burn = configuracao$burn,
      iter = configuracao$iter,
      nmodel = configuracao$nmodel,
      mcmc = configuracao$mcmc,
      g = configuracao$g,
      mprior = configuracao$mprior,
      mprior.size = numero_covariaveis / 2,
      start.value = valores_iniciais[[i]],
      user.int = FALSE,
      g.stats = TRUE,
      logfile = file.path(pasta, paste0("cadeia_", i, ".log")),
      logstep = if (modo_teste) 100 else 100000,
      force.full.ols = configuracao$force.full.ols
    )

    saveRDS(cadeias[[i]], arquivo)
  }

  saveRDS(cadeias, file.path(pasta, "todas_as_cadeias.rds"))
  cadeias
}

extrair_coeficientes <- function(cadeias, coluna) {
  tabelas <- lapply(
    cadeias,
    coef,
    exact = FALSE,
    order.by.pip = FALSE
  )
  variaveis <- rownames(tabelas[[1]])
  valores <- sapply(
    tabelas,
    function(tabela) tabela[variaveis, coluna]
  )
  if (is.null(dim(valores))) {
    valores <- matrix(valores, ncol = 1)
  }
  rownames(valores) <- variaveis
  valores
}

comparar_cadeias <- function(cadeias) {
  pips <- extrair_coeficientes(cadeias, "PIP")
  medias <- extrair_coeficientes(cadeias, "Post Mean")
  sinais <- extrair_coeficientes(cadeias, "Cond.Pos.Sign")
  colnames(pips) <- paste0("PIP_", names(cadeias))

  data.frame(
    variavel = rownames(pips),
    pips,
    PIP_media = rowMeans(pips),
    PIP_minima = apply(pips, 1, min),
    PIP_maxima = apply(pips, 1, max),
    diferenca_maxima = apply(pips, 1, function(x) max(x) - min(x)),
    Post_Mean_media = rowMeans(medias),
    Cond_Pos_Sign_media = rowMeans(sinais),
    row.names = NULL
  ) |>
    dplyr::arrange(dplyr::desc(PIP_media))
}

consolidar_cadeias <- function(cadeias) {
  pips <- extrair_coeficientes(cadeias, "PIP")
  medias <- extrair_coeficientes(cadeias, "Post Mean")
  desvios <- extrair_coeficientes(cadeias, "Post SD")
  sinais <- extrair_coeficientes(cadeias, "Cond.Pos.Sign")

  draws <- vapply(
    cadeias,
    function(x) as.numeric(summary(x)[["Draws"]]),
    numeric(1)
  )
  pesos <- draws / sum(draws)
  pesos_matriz <- matrix(
    pesos,
    nrow = nrow(pips),
    ncol = length(pesos),
    byrow = TRUE
  )

  pip_final <- as.numeric(pips %*% pesos)
  media_final <- as.numeric(medias %*% pesos)
  segundo_momento <- as.numeric((desvios^2 + medias^2) %*% pesos)
  peso_inclusao <- rowSums(pips * pesos_matriz)

  resultado <- data.frame(
    variavel = rownames(pips),
    PIP = pip_final,
    post_mean = media_final,
    post_sd = sqrt(pmax(segundo_momento - media_final^2, 0)),
    cond_pos_sign = ifelse(
      peso_inclusao > 0,
      rowSums(pips * sinais * pesos_matriz) / peso_inclusao,
      NA_real_
    ),
    PIP_maior_igual_05 = pip_final >= 0.5,
    check.names = FALSE
  )
  names(resultado)[3:5] <- c("Post Mean", "Post SD", "Cond.Pos.Sign")

  resultado |>
    dplyr::arrange(dplyr::desc(PIP))
}

diagnosticar_cadeias <- function(cadeias, especificacao, desfecho, sementes) {
  dplyr::bind_rows(lapply(seq_along(cadeias), function(i) {
    resumo <- summary(cadeias[[i]])
    data.frame(
      especificacao = especificacao,
      desfecho = desfecho,
      cadeia = names(cadeias)[i],
      semente = sementes[i],
      tamanho_medio_modelo = resumo[["Mean no. regressors"]],
      iteracoes = resumo[["Draws"]],
      burn_in = resumo[["Burnins"]],
      tempo = resumo[["Time"]],
      modelos_visitados = resumo[["No. models visited"]],
      percentual_visitado = resumo[["% visited"]],
      corr_PMP = resumo[["Corr PMP"]],
      prior_modelo = resumo[["Model Prior"]],
      g_prior = resumo[["g-Prior"]],
      shrinkage = resumo[["Shrinkage-Stats"]]
    )
  }))
}

avaliar_diagnostico <- function(diagnosticos, comparacao) {
  if (modo_teste) {
    return("teste")
  }
  corr_minima <- min(as.numeric(diagnosticos$corr_PMP), na.rm = TRUE)
  diferenca_pip <- max(comparacao$diferenca_maxima, na.rm = TRUE)
  if (corr_minima >= 0.95 && diferenca_pip <= 0.05) {
    "aprovado"
  } else {
    "revisar"
  }
}

executar_grupo <- function(modelos, nome, configuracao, sementes) {
  pasta <- file.path(pasta_raiz_resultados, nome)
  pasta_tabelas <- file.path(pasta, "tabelas_tecnicas")
  dir.create(pasta_tabelas, recursive = TRUE, showWarnings = FALSE)

  objetos <- lapply(names(modelos), function(desfecho) {
    estimar_cadeias(
      modelos[[desfecho]],
      file.path(pasta, desfecho),
      configuracao,
      sementes
    )
  })
  names(objetos) <- names(modelos)

  comparacoes <- lapply(objetos, comparar_cadeias)
  consolidados <- lapply(objetos, consolidar_cadeias)
  diagnosticos <- dplyr::bind_rows(
    lapply(names(objetos), function(desfecho) {
      diagnosticar_cadeias(
        objetos[[desfecho]],
        nome,
        desfecho,
        sementes
      )
    })
  )

  resumos <- dplyr::bind_rows(lapply(names(objetos), function(desfecho) {
    diagnostico <- diagnosticos[
      diagnosticos$desfecho == desfecho,
      ,
      drop = FALSE
    ]
    data.frame(
      especificacao = nome,
      desfecho = desfecho,
      cadeias = nrow(diagnostico),
      iteracoes_retidas = sum(as.numeric(diagnostico$iteracoes)),
      burn_in_total = sum(as.numeric(diagnostico$burn_in)),
      corr_PMP_minima = min(as.numeric(diagnostico$corr_PMP)),
      corr_PMP_maxima = max(as.numeric(diagnostico$corr_PMP)),
      maior_diferenca_PIP = max(
        comparacoes[[desfecho]]$diferenca_maxima
      ),
      modelos_visitados_por_cadeia = paste(
        diagnostico$modelos_visitados,
        collapse = ";"
      ),
      status = avaliar_diagnostico(
        diagnostico,
        comparacoes[[desfecho]]
      )
    )
  }))

  for (desfecho in names(objetos)) {
    write.csv(
      comparacoes[[desfecho]],
      file.path(pasta_tabelas, paste0("comparacao_", desfecho, ".csv")),
      row.names = FALSE,
      fileEncoding = "UTF-8"
    )
    write.csv(
      consolidados[[desfecho]],
      file.path(pasta_tabelas, paste0("resultado_", desfecho, ".csv")),
      row.names = FALSE,
      fileEncoding = "UTF-8"
    )
  }

  write.csv(
    diagnosticos,
    file.path(pasta_tabelas, "diagnosticos_cadeias.csv"),
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )
  write.csv(
    resumos,
    file.path(pasta_tabelas, "resumo_diagnosticos.csv"),
    row.names = FALSE,
    fileEncoding = "UTF-8"
  )
  saveRDS(objetos, file.path(pasta, "resultados.rds"))

  list(
    objetos = objetos,
    comparacoes = comparacoes,
    consolidados = consolidados,
    diagnosticos = diagnosticos,
    resumo = resumos
  )
}

# 9. Execucao dos modelos -------------------------------------------------

resultado_principal <- executar_grupo(
  modelos_principais,
  "principal",
  configuracao_principal,
  sementes_principais
)

resultado_ampliado <- executar_grupo(
  modelos_ampliados,
  "ampliado",
  configuracao_principal,
  sementes_principais
)

resultado_escalas <- executar_grupo(
  modelos_sensibilidade_escala,
  "sensibilidade_escalas",
  configuracao_sensibilidade,
  sementes_sensibilidade
)

resultado_sem_fortaleza <- executar_grupo(
  modelos_sem_fortaleza,
  "sensibilidade_sem_fortaleza",
  configuracao_sensibilidade,
  sementes_sensibilidade
)

resumos_gerais <- dplyr::bind_rows(
  resultado_principal$resumo,
  resultado_ampliado$resumo,
  resultado_escalas$resumo,
  resultado_sem_fortaleza$resumo
)

write.csv(
  resumos_gerais,
  file.path(pasta_raiz_resultados, "resumo_geral_diagnosticos.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

saveRDS(
  list(
    principal = resultado_principal,
    ampliado = resultado_ampliado,
    escalas = resultado_escalas,
    sem_fortaleza = resultado_sem_fortaleza
  ),
  file.path(pasta_raiz_resultados, "todos_os_resultados.rds")
)

if (interactive()) {
  View(resumos_gerais, title = "Resumo dos diagnosticos")
}

if (!modo_teste && any(resumos_gerais$status == "revisar")) {
  warning(
    "Uma ou mais estimacoes exigem revisao dos diagnosticos. ",
    "Consulte resumo_geral_diagnosticos.csv.",
    call. = FALSE
  )
} else {
  message("Todas as estimacoes programadas foram concluidas.")
}

