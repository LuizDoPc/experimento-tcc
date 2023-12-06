library(tidyverse)
library(readr)
database <- read_csv("dados/teste1.csv")

data_grouped <- database %>%
  group_by(experiment_id, request_size) %>%
  summarize(
    mean_c = mean(value, na.rm = TRUE),
    stddev_c = sd(value, na.rm = TRUE)
  )

data <- database %>%
  mutate(
    language = stringr::str_extract(app_name, "java|go"),
    protocol = stringr::str_extract(app_name, "http|grpc")
  )

data$language <- as.factor(data$language)
data$protocol <- as.factor(data$protocol)
data$request_size <- as.factor(data$request_size)

data_big <- subset(data, request_size == "big")
model_big <- aov(value ~ language * protocol, data = data_big)
summary(model_big)

data_small <- subset(data, request_size == "small")
model_small <- aov(value ~ language * protocol, data = data_small)
summary(model_small)

print(data_grouped)
