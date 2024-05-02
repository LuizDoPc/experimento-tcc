library(tidyverse)
library(readr)
library(reshape2)
library(stats)
database <- read_csv("dados/experimento2.csv")

# separate language and protocol in two columns
data <- database %>%
  mutate(
    language = stringr::str_extract(app_name, "java|go"),
    protocol = stringr::str_extract(app_name, "http|grpc")
  )

data$language <- as.factor(data$language)
data$protocol <- as.factor(data$protocol)
data$request_size <- as.factor(data$request_size)

# data for tests
javahttp <- filter(database, request_size=="big", app_name=="javahttp")
javagrpc <- filter(database, request_size=="big", app_name=="javagrpc")
gohttp <- filter(database, request_size=="big", app_name=="gohttp")
gogrpc <- filter(database, request_size=="big", app_name=="gogrpc")

dataBig <- filter(data, request_size=="big")
dataSmall <- filter(data, request_size=="small")
set.seed(7)
sampled_data <- sample_n(javagrpc, size = 140)

#testing normality
hist(sampled_data$value, breaks = "Sturges")
qqnorm(sampled_data$value)
qqline(sampled_data$value)

# testing differences between apps
print(wilcox.test(javahttp$value, javagrpc$value, paired = FALSE))
print(wilcox.test(javahttp$value, gohttp$value, paired = FALSE))
print(wilcox.test(javahttp$value, gogrpc$value, paired = FALSE))
print(wilcox.test(javagrpc$value, gohttp$value, paired = FALSE))
print(wilcox.test(javagrpc$value, gogrpc$value, paired = FALSE))
print(wilcox.test(gohttp$value, gogrpc$value, paired = FALSE))

kruskal.test(value ~ protocol, data = dataBig)
kruskal.test(value ~ language, data = dataBig)
dataBig$combined_factor <- interaction(dataBig$protocol, dataBig$language)
kruskal.test(value ~ combined_factor, data = dataBig)

#mod = lm(log(value +1) ~ protocol + language + protocol:language, data = dataSmall)
# removing outliers
#res_scaled = abs(scale(mod$residuals))
#out = res_scaled > 3.5
#dados = dataBig[!out,] 

# ???? transformation
sampled_data = sample_n(dataSmall, size = 5000)
mod = lm(log(value + 1) ~ protocol + language + protocol:language, data = sampled_data)
hist(mod$residuals)
qqnorm(mod$residuals)
qqline(mod$residuals)
print(mod)
shapiro.test(mod$residuals)

# mean transformed model
dados_mean = aggregate(value ~ language + protocol+experiment_id, FUN = median, data = dataSmall)
mod = lm(value ~ protocol + language + protocol:language, data = dados_mean)

# model diagnostics
print(mod)
shapiro.test(mod$residuals)
hist(mod$residuals)
qqnorm(mod$residuals)
qqline(mod$residuals)
anova(mod)

var_raw = var(dataBig$value)
var_agg = var(dados_mean$value)
print(paste("Variância dos dados brutos: ", var_raw))
print(paste("Variância dos dados agregados: ", var_agg))

ggplot(dados_mean, aes(x = language, y = value, fill = language)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Impacto da Linguagem de Programação na Performance",
       x = "Linguagem de Programação",
       y = "Valor Médio da Performance") +
  theme_minimal()

ggplot(dados_mean, aes(x = protocol, y = value, fill = protocol)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Impacto do Protocolo na Performance",
       x = "Protocolo",
       y = "Valor Médio da Performance") +
  theme_minimal()

