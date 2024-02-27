library(tidyverse)
library(readr)
library(reshape2)
library(stats)
database <- read_csv("dados/experimento1.csv")

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
javahttp <- filter(database, request_size=="big", app_name=="javahttp", experiment_id==7)
javagrpc <- filter(database, request_size=="big", app_name=="javagrpc", experiment_id==7)
gohttp <- filter(database, request_size=="big", app_name=="gohttp", experiment_id==7)
gogrpc <- filter(database, request_size=="big", app_name=="gogrpc", experiment_id==7)
dataBig <- filter(data, request_size=="big")
dataSmall <- filter(data, request_size=="small")


hist(javahttp$value, breaks = "Sturges")
qqnorm(javahttp$value)
qqline(javahttp$value)
shapiro.test(javahttp$value)


# testing differences between apps
print(wilcox.test(javahttp$value, javagrpc$value, paired = FALSE))
print(wilcox.test(javahttp$value, gohttp$value, paired = FALSE))
print(wilcox.test(javahttp$value, gogrpc$value, paired = FALSE))
print(wilcox.test(javagrpc$value, gohttp$value, paired = FALSE))
print(wilcox.test(javagrpc$value, gogrpc$value, paired = FALSE))
print(wilcox.test(gohttp$value, gogrpc$value, paired = FALSE))


# Friedman test
data_wide <- dcast(dataBig, experiment_id ~ app_name, value.var = "value", fun.aggregate = mean)
head(data_wide)
data_friedman <- as.matrix(data_wide[, -1])
print(friedman.test(data_friedman))


# sqrt transformed model
mod = lm(sqrt(value) ~ protocol + language + protocol:language, data = dataBig)

kruskal.test(value ~ protocol, data = dataBig)
kruskal.test(value ~ language, data = dataBig)
dataBig$combined_factor <- interaction(dataBig$protocol, dataBig$language)
kruskal.test(value ~ combined_factor, data = dataBig)


# removing outliers
res_scaled = abs(scale(mod$residuals))
out = res_scaled > 3.5
dados = dataBig[!out,] 

# mean transformed model
dados_mean = aggregate(value ~ language + protocol+experiment_id, FUN = mean, data = dados)
mod = lm(value ~ protocol + language + protocol:language, data = dados_mean)

# model diagnostics
print(mod)
shapiro.test(mod$residuals)
hist(mod$residuals)
anova(mod)

hist(dataBig$value, main = "Histograma de Value", xlab = "Value", breaks = "Sturges")
