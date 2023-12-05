library(tidyverse)
library(readr)
javagrpc_pequeno <- read_csv("dados/pequeno/v1/javagrpc-pequeno.csv")
javahttp_pequeno <- read_csv("dados/pequeno/v1/javahttp-pequeno.csv")
gohttp_pequeno <- read_csv("dados/pequeno/v1/gohttp-pequeno.csv")
gogrpc_pequeno <- read_csv("dados/pequeno/v1/gogrpc-pequeno.csv")
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

summary_stats <- all_data %>%
  group_by(application) %>%
  summarise(
    Media = mean(Value, na.rm = TRUE),
    DesvioPadrao = sd(Value, na.rm = TRUE),
    SE = sd(Value, na.rm = TRUE) / sqrt(n()),
    ymin = Media - 1.645*SE,
    ymax = Media + 1.645*SE,
    #ymin = Media - 1.96*SE,
    #ymax = Media + 1.96*SE,
  )

all_data_new <- all_data %>%
  select(-c) %>%
  group_by(application) %>%
  mutate(id = row_number()) %>%
  ungroup()

all_data_wide <- all_data_new %>%
  pivot_wider(names_from = application, values_from = Value, id_cols = id)

all_data_wide_no_id <- select(all_data_wide, -id)

write.csv(all_data_wide_no_id, "dados/grande/all_data_wide.csv", row.names = FALSE)

media_por_coluna <- all_data_wide %>%
  select(-id) %>%
  summarise_all(mean, na.rm = TRUE)

all_data_joined <- all_data %>%
  left_join(summary_stats, by = "application")

box_plot <- ggplot(all_data_joined, aes(x=application, y=Value)) +
  geom_boxplot() +
  stat_summary(fun = mean, geom = "point", shape = 20, size = 3, color = "red") +
  geom_errorbar(aes(ymin = ymin, ymax = ymax), width = 0.2, color = "red") +
  labs(title = "Comparação de Desempenho com Intervalo de Confiança de 90%", x = "Aplicação", y = "Valor") +
  theme_minimal()


print(box_plot)
print(summary_stats)
print(media_por_coluna)

# Substitua os valores de desvio padrão e média conforme necessário
s_javahttp <- sd(javahttp_grande$Value, na.rm = TRUE)
s_javagrpc <- sd(javagrpc_grande$Value, na.rm = TRUE)
s_gohttp <- sd(gohttp_grande$Value, na.rm = TRUE)
s_gogrpc <- sd(gogrpc_grande$Value, na.rm = TRUE)

E_javahttp <- mean(javahttp_grande$Value, na.rm = TRUE)
E_javagrpc <- mean(javagrpc_grande$Value, na.rm = TRUE)
E_gohttp <- mean(gohttp_grande$Value, na.rm = TRUE)
E_gogrpc <- mean(gogrpc_grande$Value, na.rm = TRUE)

# Definindo a precisão desejada e o valor z
d <- 0.05
z <- 1.96

# Calculando o número de repetições
r_javahttp <- (z * s_javahttp / (d * E_javahttp))^2
r_javagrpc <- (z * s_javagrpc / (d * E_javagrpc))^2
r_gohttp <- (z * s_gohttp / (d * E_gohttp))^2
r_gogrpc <- (z * s_gogrpc / (d * E_gogrpc))^2

# Resultados
r_javahttp
r_javagrpc
r_gohttp
r_gogrpc
