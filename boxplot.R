library(tidyverse)
library(readr)
javagrpc_pequeno <- read_csv("dados/pequeno/v2/javagrpc-pequeno.csv")
javahttp_pequeno <- read_csv("dados/pequeno/v2/javahttp-pequeno.csv")
gohttp_pequeno <- read_csv("dados/pequeno/v2/gohttp-pequeno.csv")
gogrpc_pequeno <- read_csv("dados/pequeno/v2/gogrpc-pequeno.csv")
javahttp_grande <- read_csv("dados/grande/javahttp-grande.csv")
javagrpc_grande <- read_csv("dados/grande/javagrpc-grande.csv")
gohttp_grande <- read_csv("dados/grande/gohttp-grande.csv")
gogrpc_grande <- read_csv("dados/grande/gogrpc-grande.csv")

# all_data <- bind_rows(
#   mutate(gogrpc_pequeno, application="gogrpc"),
#   mutate(gohttp_pequeno, application="gohttp"),
#   mutate(javahttp_pequeno, application="javahttp"),
#   mutate(javagrpc_pequeno, application="javagrpc")
# )

all_data <- bind_rows(
  mutate(gogrpc_grande, application="gogrpc"),
  mutate(gohttp_grande, application="gohttp"),
  mutate(javahttp_grande, application="javahttp"),
  mutate(javagrpc_grande, application="javagrpc")
)


all_data <- all_data %>%
  select(c, Value, application)

box_plot <- ggplot(all_data, aes(x=application, y=Value)) +
  geom_boxplot() +
  labs(title = "Comparação de Desempenho", x = "Aplicação", y = "Valor") +
  theme_minimal()

print(box_plot)

summary_stats <- all_data %>%
  group_by(application) %>%
  summarise(
    Media = mean(Value, na.rm = TRUE),
    DesvioPadrao = sd(Value, na.rm = TRUE)
  )

print(summary_stats)

