library(tidyverse)
library(readr)
database <- read_csv("dados/experimento2.csv")

expSmall <- filter(database, request_size=="small", experiment_id==2 | experiment_id==3 | experiment_id==4 | experiment_id==5)
expBig <- filter(database, request_size=="big", experiment_id==1 | experiment_id==3 | experiment_id==4 | experiment_id==5 | experiment_id==6)
exp1 <- expBig

javahttp <- filter(exp1, app_name=="javahttp")
javagrpc <- filter(exp1, app_name=="javagrpc")
gohttp <- filter(exp1, app_name=="gohttp")
gogrpc <- filter(exp1, app_name=="gogrpc")

# removing outliers with IQR

remover_outliers <- function(dados, campo) {
  # Calculando o primeiro e terceiro quartis
  Q1 <- quantile(dados[[campo]], 0.25)
  Q3 <- quantile(dados[[campo]], 0.75)
  IQR <- Q3 - Q1
  
  # Definindo os limites para considerar outliers
  limite_inferior <- Q1 - 1.5 * IQR
  limite_superior <- Q3 + 1.5 * IQR
  
  # Filtrando os dados para remover outliers
  dados_filtrados <- dados[dados[[campo]] >= limite_inferior & dados[[campo]] <= limite_superior, ]
  
  return(dados_filtrados)
}

#javahttp <- remover_outliers(javahttp, "value")
#javagrpc <- remover_outliers(javagrpc, "value")
#gohttp <- remover_outliers(gohttp, "value")
#gogrpc <- remover_outliers(gogrpc, "value")

# data transformation for time measures
javahttp$value <- sqrt(javahttp$value)
javagrpc$value <- sqrt(javagrpc$value)
gohttp$value <- sqrt(gohttp$value)
gogrpc$value <- sqrt(gogrpc$value)

# test data normality with histogram and shapiro test

hist(javahttp$value, breaks="Sturges")
hist(javagrpc$value, breaks="Sturges")
hist(gohttp$value, breaks="Sturges")
hist(gogrpc$value, breaks="Sturges")

qqnorm(javahttp$value)
qqline(javahttp$value)
qqnorm(javagrpc$value)
qqline(javagrpc$value)
qqnorm(gohttp$value)
qqline(gohttp$value)
qqnorm(gogrpc$value)
qqline(gogrpc$value)


shapiro.test(javahttp$value)
shapiro.test(javagrpc$value)
shapiro.test(gohttp$value)
shapiro.test(gogrpc$value)

