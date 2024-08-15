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


set.seed(77777)
javahttp <- sample_n(javahttp, 10)
javagrpc <- sample_n(javagrpc, 10)
gohttp <- sample_n(gohttp, 10)
gogrpc <- sample_n(gogrpc, 10)


xjavahttp <- mean(javahttp$value)
sjavahttp <- sd(javahttp$value)

xjavagrpc <- mean(javagrpc$value)
sjavagrpc <- sd(javagrpc$value)

xgohttp <- mean(gohttp$value)
sgohttp <- sd(gohttp$value)

xgogrpc <- mean(gogrpc$value)
sgogrpc <- sd(gogrpc$value)

n <- 10
z <- 1.833 # 95% 9df
r <- 5

szjavahttp = ((100*z*sjavagrpc)/(r*xjavahttp))^2
szjavagrpc = ((100*z*sjavagrpc)/(r*xjavagrpc))^2
szgohttp = ((100*z*sjavagrpc)/(r*xgohttp))^2
szgogrpc = ((100*z*sjavagrpc)/(r*xgogrpc))^2
