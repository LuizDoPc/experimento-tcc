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

data_joined <- rbind(javahttp, javagrpc, gohttp, gogrpc)

print(wilcox.test(javahttp$value, javagrpc$value, paired = FALSE))
print(wilcox.test(javahttp$value, gohttp$value, paired = FALSE))
print(wilcox.test(javahttp$value, gogrpc$value, paired = FALSE))
print(wilcox.test(javagrpc$value, gohttp$value, paired = FALSE))
print(wilcox.test(javagrpc$value, gogrpc$value, paired = FALSE))
print(wilcox.test(gohttp$value, gogrpc$value, paired = FALSE))

kruskal.test(value ~ protocol, data = data_joined)
kruskal.test(value ~ language, data = data_joined)
data_joined$combined_factor <- interaction(data_joined$protocol, data_joined$language)
kruskal.test(value ~ combined_factor, data = data_joined)

mean_javahttp <- mean(javahttp$value)
mean_javagrpc <- mean(javagrpc$value)
mean_gohttp <- mean(gohttp$value)
mean_gogrpc <- mean(gogrpc$value)

median_javahttp <- median(javahttp$value)
median_javagrpc <- median(javagrpc$value)
median_gohttp <- median(gohttp$value)
median_gogrpc <- median(gogrpc$value)

stddev_javahttp <- sd(javahttp$value)
stddev_javagrpc <- sd(javagrpc$value)
stddev_gohttp <- sd(gohttp$value)
stddev_gogrpc <- sd(gogrpc$value)

mean_javahttp
mean_javagrpc
mean_gohttp
mean_gogrpc

stddev_javahttp
stddev_javagrpc
stddev_gohttp
stddev_gogrpc

ggplot(gohttp, aes(x=as.factor(id), y=value)) +
  geom_bar(stat="identity") +
  theme_minimal() +
  labs(title="Gráfico de Colunas das Requisições",
       x="Identificador Único",
       y="Valor da Requisição")


data_joined$app_name <- factor(data_joined$app_name,
                               levels = c("gogrpc", "gohttp", "javagrpc", "javahttp"),
                               labels = c("(Go,gRPC)", "(Go,REST)", "(Java,gRPC)", "(Java,REST)"))

boxplot(value ~ app_name, data = data_joined, col = "lightblue", main = "",
        xlab = "Aplicação", ylab = "Duração da Requisição")
