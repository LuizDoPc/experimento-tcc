library(tidyverse)
library(readr)
database <- read_csv("dados/experimento1.csv")

# mean and std dev for each app
data_grouped <- database %>%
  group_by(experiment_id, request_size, app_name) %>%
  summarize(
    mean_c = mean(value, na.rm = TRUE),
    stddev_c = sd(value, na.rm = TRUE)
  )

# separate language and protocol in two columns
data <- database %>%
  mutate(
    language = stringr::str_extract(app_name, "java|go"),
    protocol = stringr::str_extract(app_name, "http|grpc")
  )

data$language <- as.factor(data$language)
data$protocol <- as.factor(data$protocol)
data$request_size <- as.factor(data$request_size)

# ANOVA
data_big <- subset(data, request_size == "big")
model_big <- aov(value ~ language * protocol, data = data_big)
summary(model_big)

data_small <- subset(data, request_size == "small")
model_small <- aov(value ~ language * protocol, data = data_small)
summary(model_small)


print(n=72, data_grouped)
aggregate(value ~ app_name + request_size, data = database, mean)
aggregate(value ~ app_name + request_size, data = database, sd)


graphic_data <- subset(database, request_size == "big")
graphic_data <- subset(graphic_data, experiment_id == 1)

summary <- graphic_data %>%
  group_by(app_name) %>%
  summarize(
    mean = mean(value, na.rm = TRUE),
    sd = sd(value, na.rm = TRUE),
    se = sd(value, na.rm = TRUE) / sqrt(n()),
    # ymin = mean - 1.96*se,
    # ymax = mean + 1.96*se
    ymin = mean - 2.576*se,
    ymax = mean + 2.576*se
  )

graphic_data_joined <- graphic_data %>%
  left_join(summary, by = "app_name")
   
box_plot <- ggplot(graphic_data_joined, aes(x=app_name, y=value)) +
  geom_boxplot() +
  stat_summary(fun = mean, geom = "point", shape = 20, size = 3, color = "red") +
  geom_errorbar(aes(ymin = ymin, ymax = ymax), width = 0.2, color = "red") +
  labs(title = "Comparação de Desempenho com Intervalo de Confiança de 99%", x = "Aplicação", y = "Valor") +
  theme_minimal()


print(box_plot)

