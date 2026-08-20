# Diagnostico de dependencia espacial dos residuos do BMA principal
# Nao substitui o BMA. Apenas diagnostica autocorrelacao espacial residual.
# Le os objetos ja aprovados em resultados/estimacoes/principal; nao reestima nada.

pacotes_necessarios <- c("readxl", "dplyr", "BMS", "sf", "spdep", "geobr")
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
  library(sf)
  library(spdep)
  library(geobr)
})

semente_moran <- 20200731L
n_permutacoes <- 9999L

pasta_saida <- file.path("resultados", "diagnostico_espacial")
dir.create(pasta_saida, recursive = TRUE, showWarnings = FALSE)

log_linhas <- character(0)
registrar <- function(...) {
  linha <- paste0(...)
  log_linhas <<- c(log_linhas, linha)
  message(linha)
}

registrar("=== Diagnostico de dependencia espacial ===")
registrar("Data/hora: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"))

# 1. Recompor os desfechos padronizados exatamente como em covid_bma.R -----
# Reproduz apenas as formulas necessarias para obter, na mesma ordem de
# linhas de dadosv6.xlsx, o codigo IBGE e os tres desfechos padronizados
# (z_log_casos100k, z_log_obitos100k, z_logit_letal). Serve tambem como
# verificacao cruzada: esses valores devem bater com a primeira coluna de
# X.data dentro de cada objeto bma ja estimado.

arquivo_dados <- "dadosv6.xlsx"
if (!file.exists(arquivo_dados)) {
  stop("dadosv6.xlsx nao encontrado na pasta do projeto.", call. = FALSE)
}

dados <- read_excel(arquivo_dados, sheet = "raw", na = c("", "NA"))
names(dados) <- trimws(names(dados))

dados <- dados |>
  mutate(across(c(codigo_ibge, covtotal, obito, cov100k, pop), as.numeric))

if (nrow(dados) != 184L) {
  stop("Esperava 184 municipios em dadosv6.xlsx; encontrados ", nrow(dados), ".", call. = FALSE)
}
if (anyNA(dados$codigo_ibge) || anyDuplicated(dados$codigo_ibge)) {
  stop("codigo_ibge deve estar preenchido e ser unico.", call. = FALSE)
}

padronizar <- function(x) as.numeric((x - mean(x)) / sd(x))

dados <- dados |>
  mutate(
    log_casos100k = log(cov100k),
    log_obitos100k = log((obito + 0.5) / pop * 100000),
    logit_letal = log((obito + 0.5) / (covtotal - obito + 0.5)),
    z_log_casos100k = padronizar(log_casos100k),
    z_log_obitos100k = padronizar(log_obitos100k),
    z_logit_letal = padronizar(logit_letal)
  )

registrar("Base lida: ", nrow(dados), " municipios, ordem de linhas preservada de dadosv6.xlsx.")

# 2. Carregar os objetos BMA principais ja aprovados ------------------------

caminho_resultados <- file.path("resultados", "estimacoes", "principal", "resultados.rds")
if (!file.exists(caminho_resultados)) {
  stop(
    "Nao encontrei ", caminho_resultados,
    ". Rode covid_bma.R antes deste script; este script nao reestima o BMA.",
    call. = FALSE
  )
}
objetos_principais <- readRDS(caminho_resultados)

desfechos <- c(
  casos = "z_log_casos100k",
  obitos = "z_log_obitos100k",
  letalidade = "z_logit_letal"
)

# 3. Verificacao de correspondencia entre a base recomposta e X.data --------

tolerancia_correspondencia <- 1e-6

for (nome in names(desfechos)) {
  cadeias <- objetos_principais[[nome]]
  coluna_z <- desfechos[[nome]]

  for (cad in names(cadeias)) {
    x_data <- cadeias[[cad]]$arguments$X.data
    if (nrow(x_data) != nrow(dados)) {
      stop(
        "Numero de linhas de X.data (", nrow(x_data), ") difere da base (",
        nrow(dados), ") em ", nome, "/", cad, ".",
        call. = FALSE
      )
    }
    diferenca <- max(abs(x_data[[1]] - dados[[coluna_z]]))
    registrar(
      "Correspondencia ", nome, "/", cad, ": diferenca maxima entre ",
      coluna_z, " recomposto e X.data[,1] = ", format(diferenca, scientific = TRUE)
    )
    if (diferenca > tolerancia_correspondencia) {
      stop(
        "Divergencia acima da tolerancia entre a base recomposta e o desfecho ",
        "usado na estimacao de ", nome, "/", cad, ". Interrompendo.",
        call. = FALSE
      )
    }
  }
}

registrar("Todas as verificacoes de correspondencia entre a base e X.data passaram.")

# 4. Residuos model-averaged por desfecho ------------------------------------
# predict.bma(objeto) com newdata = NULL retorna os valores ajustados dentro
# da amostra a partir dos coeficientes model-averaged (estimates.bma),
# incluindo o tratamento correto do intercepto via .post.constant(). Duas
# cadeias foram estimadas por desfecho e ja foram aprovadas nos diagnosticos
# do BMA (Corr PMP >= 0,95; diferenca de PIP <= 0,05). Combinamos as
# previsoes das duas cadeias com o mesmo peso por numero de draws usado em
# consolidar_cadeias() no covid_bma.R, para manter a mesma convencao do
# projeto ao consolidar cadeias multiplas. Esta combinacao e uma
# operacionalizacao do estudo, nao um procedimento descrito diretamente na
# documentacao do BMS para multiplas cadeias independentes.

calcular_residuos <- function(cadeias) {
  draws <- vapply(cadeias, function(x) as.numeric(summary(x)[["Draws"]]), numeric(1))
  pesos <- draws / sum(draws)

  previsoes <- vapply(
    cadeias,
    function(objeto) as.numeric(predict(objeto, exact = FALSE)),
    numeric(nrow(dados))
  )

  ajustado <- as.numeric(previsoes %*% pesos)
  ajustado
}

residuos <- data.frame(
  codigo_ibge = dados$codigo_ibge,
  municipio = dados$Municipios
)

for (nome in names(desfechos)) {
  coluna_z <- desfechos[[nome]]
  ajustado <- calcular_residuos(objetos_principais[[nome]])
  residuos[[paste0("residuo_", nome)]] <- dados[[coluna_z]] - ajustado
}

registrar("Residuos model-averaged calculados para casos, obitos e letalidade.")

write.csv(
  residuos,
  file.path(pasta_saida, "residuos_bma.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

# 5. Malha municipal oficial (IBGE via geobr) --------------------------------
# Fonte: IBGE, malha municipal, ano 2020, obtida via pacote geobr (mantido
# pelo IPEA), que espelha os arquivos oficiais do IBGE (Malhas Territoriais).
# CRS: SIRGAS 2000 (EPSG:4674), padrao do IBGE para a malha municipal.

registrar("Baixando malha municipal do Ceara via geobr (IBGE, ano 2020)...")
malha <- geobr::read_municipality(code_muni = "CE", year = 2020, showProgress = FALSE)
registrar(
  "Malha obtida: ", nrow(malha), " municipios. CRS: ",
  sf::st_crs(malha)$input, ". Fonte: IBGE via geobr, ano 2020."
)

geometrias_invalidas <- sum(!sf::st_is_valid(malha))
registrar("Geometrias invalidas antes de correcao: ", geometrias_invalidas)
if (geometrias_invalidas > 0L) {
  malha <- sf::st_make_valid(malha)
  registrar("Geometrias invalidas corrigidas com st_make_valid().")
}

if (nrow(malha) != 184L || anyDuplicated(malha$code_muni)) {
  stop("A malha nao contem 184 codigos IBGE unicos.", call. = FALSE)
}

nao_correspondidos_base <- setdiff(residuos$codigo_ibge, malha$code_muni)
nao_correspondidos_malha <- setdiff(malha$code_muni, residuos$codigo_ibge)

registrar(
  "Codigos da base sem correspondencia na malha: ",
  length(nao_correspondidos_base)
)
registrar(
  "Codigos da malha sem correspondencia na base: ",
  length(nao_correspondidos_malha)
)

if (length(nao_correspondidos_base) > 0L || length(nao_correspondidos_malha) > 0L) {
  stop("Ha codigos IBGE sem correspondencia entre a base e a malha.", call. = FALSE)
}

# Reordenar a malha para a mesma ordem de codigo_ibge de 'residuos', usando
# match() por codigo_ibge -- nunca por nome ou ordem original das linhas.
indice <- match(residuos$codigo_ibge, malha$code_muni)
if (anyNA(indice)) {
  stop("Falha ao alinhar a malha aos residuos por codigo_ibge.", call. = FALSE)
}
malha_alinhada <- malha[indice, ]

if (!identical(malha_alinhada$code_muni, residuos$codigo_ibge)) {
  stop("A ordem final entre residuos e malha nao ficou identica.", call. = FALSE)
}

registrar("Malha alinhada aos residuos por codigo_ibge; ordem final identica.")

# 6. Vizinhanca Queen (principal) e Rook (sensibilidade) ---------------------

vizinhanca_queen <- spdep::poly2nb(malha_alinhada, queen = TRUE)
vizinhanca_rook <- spdep::poly2nb(malha_alinhada, queen = FALSE)

contar_ilhas <- function(nb) sum(spdep::card(nb) == 0L)

ilhas_queen <- contar_ilhas(vizinhanca_queen)
ilhas_rook <- contar_ilhas(vizinhanca_rook)

registrar("Municipios sem vizinhos (ilhas) -- Queen: ", ilhas_queen)
registrar("Municipios sem vizinhos (ilhas) -- Rook: ", ilhas_rook)

if (ilhas_queen > 0L) {
  nomes_ilhas <- residuos$municipio[spdep::card(vizinhanca_queen) == 0L]
  registrar("Municipios-ilha em Queen: ", paste(nomes_ilhas, collapse = "; "))
}
if (ilhas_rook > 0L) {
  nomes_ilhas <- residuos$municipio[spdep::card(vizinhanca_rook) == 0L]
  registrar("Municipios-ilha em Rook: ", paste(nomes_ilhas, collapse = "; "))
}

# zero.policy so e ligado se ilhas forem encontradas e documentadas aqui.
zero_policy_queen <- ilhas_queen > 0L
zero_policy_rook <- ilhas_rook > 0L
if (zero_policy_queen || zero_policy_rook) {
  registrar(
    "zero.policy ativado explicitamente porque foram encontradas ilhas ",
    "(municipios sem vizinho de primeira ordem sob o criterio correspondente). ",
    "Municipios-ilha recebem peso espacial nulo nessa matriz e nao contribuem ",
    "para a estatistica global nessa especificacao; isso e uma limitacao, nao ",
    "um tratamento que produza evidencia sobre esses municipios especificos."
  )
} else {
  registrar("Nenhuma ilha encontrada; zero.policy permanece desligado (FALSE) em ambas as matrizes.")
}

peso_queen <- spdep::nb2listw(vizinhanca_queen, style = "W", zero.policy = zero_policy_queen)
peso_rook <- spdep::nb2listw(vizinhanca_rook, style = "W", zero.policy = zero_policy_rook)

saveRDS(vizinhanca_queen, file.path(pasta_saida, "vizinhanca_queen.rds"))
saveRDS(vizinhanca_rook, file.path(pasta_saida, "vizinhanca_rook.rds"))
saveRDS(peso_queen, file.path(pasta_saida, "pesos_queen.rds"))
saveRDS(peso_rook, file.path(pasta_saida, "pesos_rook.rds"))

# 7. I de Moran global por permutacao ----------------------------------------

rodar_moran <- function(x, listw, zero_policy, semente) {
  set.seed(semente)
  spdep::moran.mc(
    x = x,
    listw = listw,
    nsim = n_permutacoes,
    alternative = "two.sided",
    zero.policy = zero_policy
  )
}

# O p-valor bilateral de spdep::moran.mc() usa punif(abs(rank - (nsim+1)/2)/(nsim+1),
# 0, 0.5, lower.tail = FALSE), que pode retornar exatamente 0 quando a estatistica
# observada e mais extrema que todas as permutacoes -- isso e um artefato de formula
# na fronteira, nao um p-valor de Monte Carlo valido (um teste por permutacao nunca
# deve reportar p = 0 exato). Recalculamos aqui com a correcao de contagem padrao
# (Davison & Hinkley, 1997): p = (1 + #{permutacoes tao ou mais extremas}) / (nsim + 1),
# bilateral como o dobro do menor lado, limitado a 1. Com 9.999 permutacoes o menor
# p-valor bilateral atingivel e 2/10.000 = 0,0002.
calcular_p_contagem_bilateral <- function(res, nsim) {
  obs <- res[nsim + 1L]
  permutacoes <- res[seq_len(nsim)]
  p_maior <- (1 + sum(permutacoes >= obs)) / (nsim + 1)
  p_menor <- (1 + sum(permutacoes <= obs)) / (nsim + 1)
  min(1, 2 * min(p_maior, p_menor))
}

matrizes <- list(
  Queen = list(listw = peso_queen, zero_policy = zero_policy_queen),
  Rook = list(listw = peso_rook, zero_policy = zero_policy_rook)
)

linhas_tabela <- list()

for (nome in names(desfechos)) {
  residuo_vetor <- residuos[[paste0("residuo_", nome)]]

  for (tipo in names(matrizes)) {
    especificacao <- matrizes[[tipo]]
    resultado <- rodar_moran(
      x = residuo_vetor,
      listw = especificacao$listw,
      zero_policy = especificacao$zero_policy,
      semente = semente_moran
    )

    pseudo_p_corrigido <- calcular_p_contagem_bilateral(resultado$res, n_permutacoes)

    conclusao <- if (pseudo_p_corrigido < 0.05) {
      "Evidencia de autocorrelacao espacial residual ao nivel de 5%."
    } else {
      "Sem evidencia de autocorrelacao espacial residual ao nivel de 5% sob esta matriz."
    }

    # moran.mc() e o teste por permutacao (Monte-Carlo); ele nao retorna a
    # expectativa/variancia analitica de moran.test(). Aqui, "valor esperado"
    # e "variancia" sao a media e a variancia empiricas da distribuicao nula
    # simulada em resultado$res (as n_permutacoes estatisticas de I sob
    # permutacao aleatoria dos residuos), o que e o valor de referencia
    # correto para um teste por permutacao. pseudo_p_valor usa a correcao de
    # contagem (ver calcular_p_contagem_bilateral); pseudo_p_valor_spdep fica
    # registrado para auditoria e mostra o valor bruto de spdep::moran.mc(),
    # que pode chegar a exatamente 0 por um artefato de formula na fronteira.
    linhas_tabela[[length(linhas_tabela) + 1L]] <- data.frame(
      desfecho = nome,
      vizinhanca = tipo,
      n_municipios = nrow(malha_alinhada),
      permutacoes = n_permutacoes,
      moran_observado = as.numeric(resultado$statistic),
      valor_esperado_simulado = mean(resultado$res),
      variancia_simulada = var(resultado$res),
      rank_observado = as.numeric(resultado$parameter),
      pseudo_p_valor = pseudo_p_corrigido,
      pseudo_p_valor_spdep = resultado$p.value,
      semente = semente_moran,
      conclusao = conclusao
    )

    registrar(
      "Moran ", nome, "/", tipo, ": I = ",
      format(as.numeric(resultado$statistic), digits = 4),
      ", p (contagem, corrigido) = ", format(pseudo_p_corrigido, digits = 4),
      ", p (spdep, bruto) = ", format(resultado$p.value, digits = 4)
    )
  }
}

tabela_moran <- dplyr::bind_rows(linhas_tabela)

write.csv(
  tabela_moran,
  file.path(pasta_saida, "tabela_moran.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

# 8. Registros finais ---------------------------------------------------------

writeLines(
  c(
    "Fonte da malha: IBGE, Malhas Territoriais, ano 2020, obtida via pacote geobr (IPEA).",
    "URL de referencia do pacote: https://ipeagit.github.io/geobr/",
    "URL institucional dos dados: https://www.ibge.gov.br/geociencias/organizacao-do-territorio/malhas-territoriais/",
    paste0("Data de acesso: ", format(Sys.Date(), "%Y-%m-%d")),
    "Sistema de referencia espacial: SIRGAS 2000 (EPSG:4674).",
    "Campo com o codigo IBGE: code_muni (malha) / codigo_ibge (base).",
    "",
    log_linhas
  ),
  file.path(pasta_saida, "log_correspondencia.txt"),
  useBytes = TRUE
)

writeLines(
  capture.output(sessionInfo()),
  file.path(pasta_saida, "sessionInfo.txt")
)

registrar("Diagnostico de dependencia espacial concluido. Saidas em ", pasta_saida, ".")
