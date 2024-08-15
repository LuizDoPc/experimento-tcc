library(tidyverse)
library(readr)
library(reshape2)
library(stats)
database <- read_csv("dados/experimento6.csv")

data <- database %>%
  mutate(
    language = stringr::str_extract(app_name, "java|go"),
    protocol = stringr::str_extract(app_name, "http|grpc")
  )

data$language <- as.factor(data$language)
data$protocol <- as.factor(data$protocol)
data$request_size <- as.factor(data$request_size)

size <- "big"
javahttp <- filter(data, request_size==size, app_name=="javahttp")
javagrpc <- filter(data, request_size==size, app_name=="javagrpc")
gohttp <- filter(data, request_size==size, app_name=="gohttp")
gogrpc <- filter(data, request_size==size, app_name=="gogrpc")

dataBig <- filter(data, request_size=="big")
dataSmall <- filter(data, request_size=="small")

remover_outliers <- function(dados, campo) {
  Q1 <- quantile(dados[[campo]], 0.25)
  Q3 <- quantile(dados[[campo]], 0.75)
  IQR <- Q3 - Q1
  
  limite_inferior <- Q1 - 3.5 * IQR
  limite_superior <- Q3 + 3.5 * IQR
  
  dados_filtrados <- dados[dados[[campo]] >= limite_inferior & dados[[campo]] <= limite_superior, ]
  
  return(dados_filtrados)
}

javahttp <- remover_outliers(javahttp, "value")
javagrpc <- remover_outliers(javagrpc, "value")
gohttp <- remover_outliers(gohttp, "value")
gogrpc <- remover_outliers(gogrpc, "value")

javahttp <- filter(javahttp, experiment_id >= 2 & experiment_id <= 6)
javagrpc <- filter(javagrpc, experiment_id >= 2 & experiment_id <= 6)
gohttp <- filter(gohttp, experiment_id >= 2 & experiment_id <= 6)
gogrpc <- filter(gogrpc, experiment_id >= 2 & experiment_id <= 6)

# exp_size <- 77
# javahttp <- javahttp %>%
#   group_by(experiment_id) %>%
#   sample_n(exp_size)
# javagrpc <- javagrpc %>%
#   group_by(experiment_id) %>%
#   sample_n(exp_size)
# gohttp <- gohttp %>%
#   group_by(experiment_id) %>%
#   sample_n(exp_size)
# gogrpc <- gogrpc %>%
#   group_by(experiment_id) %>%
#   sample_n(exp_size)


data_filtered <- bind_rows(javahttp, javagrpc, gohttp, gogrpc)

data_grouped <- data_filtered %>%
  group_by(experiment_id, app_name) %>%
  summarise(
    value = mean(value),
  )

data_grouped_extended <- data_grouped %>%
  group_by(app_name) %>%
  summarise(
    mean = mean(value),
    value = value,
    e = value - mean(value),
    experiment_id = experiment_id
  )

inner_group <- data_grouped %>%
  group_by(app_name) %>%
  summarise(
    mean = mean(value),
  )

sum_effect <- inner_group$mean[1] + inner_group$mean[3] + inner_group$mean[2] + inner_group$mean[4]
effectLang <- -inner_group$mean[1] + inner_group$mean[3] - inner_group$mean[2] + inner_group$mean[4]
effectProt <- -inner_group$mean[1] - inner_group$mean[3] + inner_group$mean[2] + inner_group$mean[4]
effectInt <- inner_group$mean[1] - inner_group$mean[3] - inner_group$mean[2] + inner_group$mean[4]

ssy <- sum(data_grouped_extended$value^2)
sse <- ssy - (20*((sum_effect/4)^2 + (effectLang/4)^2 + (effectProt/4)^2 + (effectInt/4)^2))
ss0 <- 20*((sum_effect/4)^2)
sst <- ssy - ss0
ssl <- 20*((effectLang/4)^2)
ssp <- 20*((effectProt/4)^2)
sslp <- 20*((effectInt/4)^2)


langInfluence <- ssl/sst*100
protInfluence <- ssp/sst*100
intInfluence <- sslp/sst*100

errorInfluence <- 100 - (langInfluence + protInfluence + intInfluence)

boxplot(value ~ app_name, data = data_filtered, col = "lightblue", main = "Boxplot das Requisições",
        xlab = "Aplicação", ylab = "Valor da Requisição")



sum_effect
effectLang
effectProt
effectInt

langInfluence
protInfluence
intInfluence
errorInfluence

