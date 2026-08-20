# Tabelas e graficos finais dos resultados BMA, para dar suporte a redacao
# da secao de resultados do manuscrito.
#
# Este script NAO reestima nada. Le diretamente as tabelas tecnicas ja
# produzidas e aprovadas por covid_bma.R (resultados/estimacoes/*/tabelas_
# tecnicas/resultado_*.csv) e por diagnostico_espacial.R (resultados/
# diagnostico_espacial/tabela_moran.csv), e produz versoes formatadas para o
# texto: nomes de variaveis em portugues, numeros arredondados, tabelas de
# comparacao entre especificacoes e graficos de PIP.

pacotes_necessarios <- c("dplyr", "ggplot2", "tidyr")
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
  library(dplyr)
  library(ggplot2)
  library(tidyr)
})

pasta_saida <- file.path("resultados", "tabelas_finais")
dir.create(pasta_saida, recursive = TRUE, showWarnings = FALSE)

log_linhas <- character(0)
registrar <- function(...) {
  linha <- paste0(...)
  log_linhas <<- c(log_linhas, linha)
  message(linha)
}

registrar("=== Tabelas e graficos finais dos resultados BMA ===")
registrar("Data/hora: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"))

# 1. Verificar que as tabelas de origem existem ------------------------------
# Nenhuma delas e recalculada aqui; todas ja foram produzidas por
# covid_bma.R (aprovado) e diagnostico_espacial.R (aprovado).

arquivos_origem <- c(
  principal_casos = "resultados/estimacoes/principal/tabelas_tecnicas/resultado_casos.csv",
  principal_obitos = "resultados/estimacoes/principal/tabelas_tecnicas/resultado_obitos.csv",
  principal_letalidade = "resultados/estimacoes/principal/tabelas_tecnicas/resultado_letalidade.csv",
  ampliado_casos = "resultados/estimacoes/ampliado/tabelas_tecnicas/resultado_casos.csv",
  ampliado_obitos = "resultados/estimacoes/ampliado/tabelas_tecnicas/resultado_obitos.csv",
  ampliado_letalidade = "resultados/estimacoes/ampliado/tabelas_tecnicas/resultado_letalidade.csv",
  escala_casos_nivel = "resultados/estimacoes/sensibilidade_escalas/tabelas_tecnicas/resultado_casos_nivel.csv",
  escala_obitos_nivel = "resultados/estimacoes/sensibilidade_escalas/tabelas_tecnicas/resultado_obitos_nivel.csv",
  escala_obitos_log1p = "resultados/estimacoes/sensibilidade_escalas/tabelas_tecnicas/resultado_obitos_log1p.csv",
  escala_letalidade_nivel = "resultados/estimacoes/sensibilidade_escalas/tabelas_tecnicas/resultado_letalidade_nivel.csv",
  sem_fortaleza_casos = "resultados/estimacoes/sensibilidade_sem_fortaleza/tabelas_tecnicas/resultado_casos.csv",
  sem_fortaleza_obitos = "resultados/estimacoes/sensibilidade_sem_fortaleza/tabelas_tecnicas/resultado_obitos.csv",
  sem_fortaleza_letalidade = "resultados/estimacoes/sensibilidade_sem_fortaleza/tabelas_tecnicas/resultado_letalidade.csv",
  diagnostico_espacial = "resultados/diagnostico_espacial/tabela_moran.csv"
)

faltantes <- arquivos_origem[!file.exists(arquivos_origem)]
if (length(faltantes) > 0L) {
  stop(
    "Arquivos de origem ausentes (rode covid_bma.R e diagnostico_espacial.R antes deste script): ",
    paste(faltantes, collapse = "; "),
    call. = FALSE
  )
}
registrar("Todos os ", length(arquivos_origem), " arquivos de origem foram encontrados.")

ler_resultado <- function(caminho) {
  read.csv(caminho, stringsAsFactors = FALSE, encoding = "UTF-8")
}

# 2. Nomes das variaveis em portugues, conforme DICIONARIO_DADOS_FASE_1.md ---
# Mapa por CODIGO DA VARIAVEL (nao por posicao), igual a "Nome para o texto"
# do dicionario. energia100k e derivada e nao tem linha propria no
# dicionario; o nome abaixo segue a mesma logica de con.energia + a
# transformacao por 100 mil habitantes ja documentada la.

nomes_portugues <- c(
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
  int.asma = "Internações por asma",
  recursofed = "Transferências federais para combate à COVID-19",
  auxem = "Auxílio emergencial"
)

nome_para_texto <- function(codigo_variavel) {
  codigo_base <- sub("^z_", "", codigo_variavel)
  nome <- nomes_portugues[codigo_base]
  if (anyNA(nome)) {
    faltando <- codigo_variavel[is.na(nome)]
    stop(
      "Variavel sem nome em portugues mapeado: ", paste(faltando, collapse = ", "),
      ". Atualize 'nomes_portugues' antes de continuar.",
      call. = FALSE
    )
  }
  unname(nome)
}

rotulos_desfecho <- c(casos = "Casos", obitos = "Óbitos", letalidade = "Letalidade")

# 3. Tabela principal por desfecho -------------------------------------------
# Tabela completa do modelo principal (35 covariaveis), ordenada por PIP,
# com nome em portugues, PIP, media posterior, desvio padrao posterior,
# direcao (derivada de Cond.Pos.Sign > 0.5) e destaque de PIP >= 0.5.

formatar_tabela_principal <- function(caminho, nome_desfecho) {
  tabela <- ler_resultado(caminho)
  tabela |>
    mutate(
      desfecho = rotulos_desfecho[[nome_desfecho]],
      nome_variavel = nome_para_texto(variavel),
      direcao = ifelse(Cond.Pos.Sign > 0.5, "positiva", "negativa"),
      PIP = round(PIP, 4),
      Post.Mean = round(Post.Mean, 4),
      Post.SD = round(Post.SD, 4),
      Cond.Pos.Sign = round(Cond.Pos.Sign, 4)
    ) |>
    select(
      desfecho, nome_variavel, variavel_codigo = variavel, PIP,
      media_posterior = Post.Mean, desvio_padrao_posterior = Post.SD,
      prob_sinal_positivo = Cond.Pos.Sign, direcao,
      pip_maior_igual_05 = PIP_maior_igual_05
    ) |>
    arrange(desc(PIP))
}

tabela_principal_casos <- formatar_tabela_principal(arquivos_origem[["principal_casos"]], "casos")
tabela_principal_obitos <- formatar_tabela_principal(arquivos_origem[["principal_obitos"]], "obitos")
tabela_principal_letalidade <- formatar_tabela_principal(arquivos_origem[["principal_letalidade"]], "letalidade")

write.csv(tabela_principal_casos, file.path(pasta_saida, "tabela_principal_casos.csv"), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(tabela_principal_obitos, file.path(pasta_saida, "tabela_principal_obitos.csv"), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(tabela_principal_letalidade, file.path(pasta_saida, "tabela_principal_letalidade.csv"), row.names = FALSE, fileEncoding = "UTF-8")

tabela_principal_combinada <- bind_rows(
  tabela_principal_casos, tabela_principal_obitos, tabela_principal_letalidade
)
write.csv(
  tabela_principal_combinada,
  file.path(pasta_saida, "tabela_principal_combinada.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)
registrar(
  "Tabela principal por desfecho gerada (35 covariaveis x 3 desfechos = ",
  nrow(tabela_principal_combinada), " linhas)."
)

# 4. Resumo das sensibilidades -------------------------------------------------
# Para cada desfecho, PIP na especificacao principal, ampliada, escala(s)
# alternativa(s) e sem Fortaleza, unidas SEMPRE por codigo da variavel (nunca
# por posicao ou ordem de linha). Usa full_join (uniao completa), nao
# left_join: recursofed e auxem existem so no modelo ampliado (as demais
# especificacoes usam covariaveis_principais_modelo, sem as fiscais), entao
# um left_join a partir do principal as descartaria por completo. Com
# full_join elas aparecem como linhas extras, com NA nas colunas de
# especificacoes que nao as incluem.

pip_de <- function(caminho) {
  ler_resultado(caminho) |> select(variavel, PIP)
}

construir_resumo_sensibilidade <- function(nome_desfecho, caminho_principal, caminho_ampliado, colunas_escala, caminho_sem_fortaleza) {
  base <- pip_de(caminho_principal) |> rename(PIP_principal = PIP)
  base <- base |> full_join(pip_de(caminho_ampliado) |> rename(PIP_ampliado = PIP), by = "variavel")
  for (nome_coluna in names(colunas_escala)) {
    base <- base |>
      full_join(
        pip_de(colunas_escala[[nome_coluna]]) |> rename(!!nome_coluna := PIP),
        by = "variavel"
      )
  }
  base <- base |> full_join(pip_de(caminho_sem_fortaleza) |> rename(PIP_sem_fortaleza = PIP), by = "variavel")

  colunas_pip <- setdiff(names(base), "variavel")
  base |>
    mutate(
      desfecho = rotulos_desfecho[[nome_desfecho]],
      nome_variavel = nome_para_texto(variavel),
      across(all_of(colunas_pip), ~ round(.x, 4)),
      n_especificacoes_pip_maior_igual_05 = rowSums(across(all_of(colunas_pip), ~ .x >= 0.5), na.rm = TRUE)
    ) |>
    select(desfecho, nome_variavel, variavel_codigo = variavel, everything()) |>
    arrange(desc(PIP_principal))
}

resumo_sensibilidade_casos <- construir_resumo_sensibilidade(
  "casos",
  arquivos_origem[["principal_casos"]],
  arquivos_origem[["ampliado_casos"]],
  list(PIP_escala_nivel = arquivos_origem[["escala_casos_nivel"]]),
  arquivos_origem[["sem_fortaleza_casos"]]
)
resumo_sensibilidade_obitos <- construir_resumo_sensibilidade(
  "obitos",
  arquivos_origem[["principal_obitos"]],
  arquivos_origem[["ampliado_obitos"]],
  list(
    PIP_escala_nivel = arquivos_origem[["escala_obitos_nivel"]],
    PIP_escala_log1p = arquivos_origem[["escala_obitos_log1p"]]
  ),
  arquivos_origem[["sem_fortaleza_obitos"]]
)
resumo_sensibilidade_letalidade <- construir_resumo_sensibilidade(
  "letalidade",
  arquivos_origem[["principal_letalidade"]],
  arquivos_origem[["ampliado_letalidade"]],
  list(PIP_escala_nivel = arquivos_origem[["escala_letalidade_nivel"]]),
  arquivos_origem[["sem_fortaleza_letalidade"]]
)

write.csv(resumo_sensibilidade_casos, file.path(pasta_saida, "resumo_sensibilidade_casos.csv"), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(resumo_sensibilidade_obitos, file.path(pasta_saida, "resumo_sensibilidade_obitos.csv"), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(resumo_sensibilidade_letalidade, file.path(pasta_saida, "resumo_sensibilidade_letalidade.csv"), row.names = FALSE, fileEncoding = "UTF-8")
registrar("Resumo das sensibilidades gerado para os tres desfechos (uniao sempre por codigo da variavel).")

# 5. Graficos de PIP -----------------------------------------------------------
# Barras horizontais por desfecho, especificacao principal, ordenadas por
# PIP, coloridas pela direcao (positiva/negativa), com linha de referencia
# em PIP = 0.5.

grafico_pip <- function(tabela, titulo, arquivo) {
  # A cor (direcao) vem de Cond.Pos.Sign, a probabilidade de sinal positivo
  # CONDICIONAL A INCLUSAO -- e uma dimensao independente do PIP (a
  # probabilidade de inclusao em si, dada pelo comprimento da barra). Uma
  # variavel com PIP baixo tem sinal tao "definido" quanto uma com PIP alto;
  # a cor sozinha nao diz nada sobre suporte para inclusao. Para nao sugerir
  # o contrario visualmente, as barras com PIP < 0,5 saem com saturacao
  # reduzida (alpha menor), e a legenda de alpha fica oculta (a explicacao
  # vai na legenda de cor e na nota de rodape).
  tabela_grafico <- tabela |>
    mutate(
      nome_variavel = factor(nome_variavel, levels = rev(nome_variavel)),
      suporte = ifelse(PIP >= 0.5, "PIP ≥ 0,5", "PIP < 0,5")
    )

  grafico <- ggplot(tabela_grafico, aes(x = nome_variavel, y = PIP, fill = direcao, alpha = suporte)) +
    geom_col(width = 0.7) +
    geom_hline(yintercept = 0.5, linetype = "dashed", color = "black", linewidth = 0.4) +
    coord_flip() +
    scale_fill_manual(
      values = c(positiva = "#2166AC", negativa = "#B2182B"),
      name = "Sinal posterior\ncondicional",
      labels = c(positiva = "Positivo", negativa = "Negativo")
    ) +
    scale_alpha_manual(values = c("PIP ≥ 0,5" = 1, "PIP < 0,5" = 0.35), guide = "none") +
    scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
    theme_minimal(base_size = 10) +
    theme(
      panel.grid.major.y = element_blank(),
      plot.background = element_rect(fill = "white", color = NA)
    ) +
    labs(
      title = titulo,
      x = NULL,
      y = "Probabilidade posterior de inclusão (PIP)",
      caption = paste(
        "Linha tracejada em PIP = 0,5. Modelo principal.",
        "A cor indica o sinal posterior condicional à inclusão (Cond.Pos.Sign),",
        "não a força de evidência para inclusão em si; barras com PIP < 0,5",
        "aparecem com saturação reduzida.",
        sep = "\n"
      )
    )

  ggsave(file.path(pasta_saida, arquivo), grafico, width = 9, height = 10.5, dpi = 150, bg = "white")
}

grafico_pip(
  tabela_principal_casos,
  "PIP por covariável — casos de COVID-19 por 100 mil habitantes",
  "grafico_pip_casos.png"
)
grafico_pip(
  tabela_principal_obitos,
  "PIP por covariável — óbitos por COVID-19 por 100 mil habitantes",
  "grafico_pip_obitos.png"
)
grafico_pip(
  tabela_principal_letalidade,
  "PIP por covariável — letalidade por COVID-19",
  "grafico_pip_letalidade.png"
)
registrar("Graficos de PIP salvos (grafico_pip_casos.png, grafico_pip_obitos.png, grafico_pip_letalidade.png).")

# 6. Quadro do diagnostico espacial -------------------------------------------
# Reformatacao de resultados/diagnostico_espacial/tabela_moran.csv com
# rotulos em portugues e numeros arredondados. Nenhum valor e recalculado.

tabela_moran <- ler_resultado(arquivos_origem[["diagnostico_espacial"]])

# diagnostico_espacial.R escreve a conclusao em ASCII puro; aqui, para o
# quadro que vai apoiar a redacao, usamos o texto com acentuacao correta.
conclusao_em_portugues <- c(
  "Evidencia de autocorrelacao espacial residual ao nivel de 5%." =
    "Evidência de autocorrelação espacial residual ao nível de 5%.",
  "Sem evidencia de autocorrelacao espacial residual ao nivel de 5% sob esta matriz." =
    "Sem evidência de autocorrelação espacial residual ao nível de 5% sob esta matriz."
)

quadro_diagnostico_espacial <- tabela_moran |>
  mutate(
    Desfecho = rotulos_desfecho[desfecho],
    Vizinhança = vizinhanca,
    N_municipios = n_municipios,
    Permutacoes = permutacoes,
    I_de_Moran = round(moran_observado, 4),
    Pseudo_p_valor = round(pseudo_p_valor, 4),
    Semente = semente,
    Conclusao = unname(conclusao_em_portugues[conclusao])
  ) |>
  select(Desfecho, Vizinhança, N_municipios, Permutacoes, I_de_Moran, Pseudo_p_valor, Semente, Conclusao)

if (anyNA(quadro_diagnostico_espacial$Conclusao)) {
  stop("Texto de conclusao nao mapeado em conclusao_em_portugues. Atualize o mapa.", call. = FALSE)
}

write.csv(
  quadro_diagnostico_espacial,
  file.path(pasta_saida, "quadro_diagnostico_espacial.csv"),
  row.names = FALSE, fileEncoding = "UTF-8"
)
registrar("Quadro do diagnostico espacial gerado (", nrow(quadro_diagnostico_espacial), " linhas).")

# 7. Registros finais -----------------------------------------------------------

writeLines(log_linhas, file.path(pasta_saida, "log.txt"), useBytes = TRUE)
writeLines(capture.output(sessionInfo()), file.path(pasta_saida, "sessionInfo.txt"))

registrar("Tabelas e graficos finais concluidos. Saidas em ", pasta_saida, ".")
