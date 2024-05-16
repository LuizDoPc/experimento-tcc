library(tidyverse)
library(readr)
database <- read_csv("dados/experimento6.csv")

expSmall <- filter(database, request_size=="small")
expBig <- filter(database, request_size=="big")
exp1 <- expSmall
javahttp <- filter(exp1, app_name=="javahttp")
javagrpc <- filter(exp1, app_name=="javagrpc")
gohttp <- filter(exp1, app_name=="gohttp")
gogrpc <- filter(exp1, app_name=="gogrpc")

remover_outliers <- function(dados, campo) {
  # Calculando o primeiro e terceiro quartis
  Q1 <- quantile(dados[[campo]], 0.25)
  Q3 <- quantile(dados[[campo]], 0.75)
  IQR <- Q3 - Q1
  
  # Definindo os limites para considerar outliers
  limite_inferior <- Q1 - 3.5 * IQR
  print(limite_inferior)
  limite_superior <- Q3 + 3.5 * IQR
  print(limite_inferior)
  
  # Filtrando os dados para remover outliers
  dados_filtrados <- dados[dados[[campo]] >= limite_inferior & dados[[campo]] <= limite_superior, ]
  
  return(dados_filtrados)
}

javahttp <- remover_outliers(javahttp, "value")
javagrpc <- remover_outliers(javagrpc, "value")
gohttp <- remover_outliers(gohttp, "value")
gogrpc <- remover_outliers(gogrpc, "value")


joined <- bind_rows(javahttp, javagrpc, gohttp, gogrpc)
grouped <- joined %>%
  group_by(experiment_id, app_name) %>%
  summarize(
    value = mean(value, na.rm = TRUE),
  )

javahttp <- filter(grouped, app_name=="javahttp", experiment_id>=3 & experiment_id<=6)
javagrpc <- filter(grouped, app_name=="javagrpc", experiment_id>=3 & experiment_id<=6)
gohttp <- filter(grouped, app_name=="gohttp", experiment_id>=3 & experiment_id<=6)
gogrpc <- filter(grouped, app_name=="gogrpc", experiment_id>=3 & experiment_id<=6)

xjavahttp <- mean(javahttp$value)
sjavahttp <- sd(javahttp$value)

xjavagrpc <- mean(javagrpc$value)
sjavagrpc <- sd(javagrpc$value)

xgohttp <- mean(gohttp$value)
sgohttp <- sd(gohttp$value)

xgogrpc <- mean(gogrpc$value)
sgogrpc <- sd(gogrpc$value)

n <- 4
z <- 2.353 # 95% 3df
r <- 5

szjavahttp = ((100*z*sjavagrpc)/(r*xjavahttp))^2
szjavagrpc = ((100*z*sjavagrpc)/(r*xjavagrpc))^2
szgohttp = ((100*z*sjavagrpc)/(r*xgohttp))^2
szgogrpc = ((100*z*sjavagrpc)/(r*xgogrpc))^2
