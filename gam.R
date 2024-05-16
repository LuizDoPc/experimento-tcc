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

size <- "small"
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


library(mgcv)
joined = rbind(javahttp, javagrpc, gohttp, gogrpc)
dataBig <- joined %>%
  mutate(across(c(language, protocol), as.factor))

gam_model <- gam(value ~ s(protocol, bs = "re") + s(language, bs = "re") +
                   ti(protocol, language, bs = "re"), data = dataBig, family = "quasipoisson")

summary(gam_model)

