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


# testing data normality
shapiro.test(javahttp$value)
shapiro.test(javagrpc$value)
shapiro.test(gohttp$value)
shapiro.test(gogrpc$value)


# testing differences between apps
print(wilcox.test(javahttp$value, javagrpc$value, paired = TRUE))
print(wilcox.test(javahttp$value, gohttp$value, paired = TRUE))
print(wilcox.test(javahttp$value, gogrpc$value, paired = TRUE))
print(wilcox.test(javagrpc$value, gohttp$value, paired = TRUE))
print(wilcox.test(javagrpc$value, gogrpc$value, paired = TRUE))
print(wilcox.test(gohttp$value, gogrpc$value, paired = TRUE))

aggregated_data <- dataBig %>%
  group_by(experiment_id, app_name) %>%
  summarise(mean_value = mean(value))
kruskal_test <- kruskal.test(mean_value ~ app_name, data=aggregated_data)
print(kruskal_test)


data_wide <- dcast(dataBig, experiment_id ~ app_name, value.var = "value", fun.aggregate = mean)
head(data_wide)
data_friedman <- as.matrix(data_wide[, -1])
print(friedman.test(data_friedman))


hist(dataBig$value, main = "Histograma de Value", xlab = "Value", breaks = "Sturges")