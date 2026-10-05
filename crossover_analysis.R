library(tidyverse)
library(readr)
library(reshape2)
library(stats)
library(mgcv)

database <- read_csv("dados/ebp_1.csv",
                     col_names = c("id", "c", "value", "experiment_id", "app_name", "request_size"),
                     col_types = cols(
                       id = col_integer(),
                       c = col_integer(),
                       value = col_double(),
                       experiment_id = col_integer(),
                       app_name = col_character(),
                       request_size = col_character()
                     ))

data <- database %>%
  mutate(
    language = stringr::str_extract(app_name, "java|go"),
    protocol = stringr::str_extract(app_name, "http|grpc"),
    payload_size = as.numeric(request_size)
  )

data$language <- as.factor(data$language)
data$protocol <- as.factor(data$protocol)
data$request_size <- as.factor(data$request_size)

remover_outliers <- function(dados, campo) {
  Q1 <- quantile(dados[[campo]], 0.25, na.rm = TRUE)
  Q3 <- quantile(dados[[campo]], 0.75, na.rm = TRUE)
  IQR <- Q3 - Q1
  
  limite_inferior <- Q1 - 3.5 * IQR
  limite_superior <- Q3 + 3.5 * IQR
  
  dados_filtrados <- dados[dados[[campo]] >= limite_inferior & dados[[campo]] <= limite_superior, ]
  
  return(dados_filtrados)
}

payload_sizes <- sort(unique(data$payload_size))

cat("=== Analyzing", length(payload_sizes), "payload sizes ===\n")
cat("Payload sizes:", paste(payload_sizes, collapse = ", "), "\n\n")

for (ps in payload_sizes) {
  cat("\n", rep("=", 60), "\n")
  cat("PAYLOAD SIZE:", ps, "\n")
  cat(rep("=", 60), "\n\n")
  
  data_ps <- filter(data, payload_size == ps)
  
  javahttp <- filter(data_ps, app_name == "javahttp")
  javagrpc <- filter(data_ps, app_name == "javagrpc")
  gohttp <- filter(data_ps, app_name == "gohttp")
  gogrpc <- filter(data_ps, app_name == "gogrpc")
  
  javahttp <- remover_outliers(javahttp, "value")
  javagrpc <- remover_outliers(javagrpc, "value")
  gohttp <- remover_outliers(gohttp, "value")
  gogrpc <- remover_outliers(gogrpc, "value")
  
  data_filtered <- bind_rows(javahttp, javagrpc, gohttp, gogrpc)
  
  if (nrow(data_filtered) < 10) {
    cat("Insufficient data for payload size", ps, "\n")
    next
  }
  
  cat("--- 2^k Factorial Analysis ---\n")
  
  data_grouped <- data_filtered %>%
    group_by(experiment_id, app_name) %>%
    summarise(
      value = mean(value),
      .groups = "drop"
    )
  
  data_grouped_extended <- data_grouped %>%
    group_by(app_name) %>%
    summarise(
      mean = mean(value),
      value = value,
      e = value - mean(value),
      experiment_id = experiment_id,
      .groups = "drop"
    )
  
  inner_group <- data_grouped %>%
    group_by(app_name) %>%
    summarise(
      mean = mean(value),
      .groups = "drop"
    )
  
  if (nrow(inner_group) == 4) {
    sum_effect <- inner_group$mean[1] + inner_group$mean[3] + inner_group$mean[2] + inner_group$mean[4]
    effectLang <- -inner_group$mean[1] + inner_group$mean[3] - inner_group$mean[2] + inner_group$mean[4]
    effectProt <- -inner_group$mean[1] - inner_group$mean[3] + inner_group$mean[2] + inner_group$mean[4]
    effectInt <- inner_group$mean[1] - inner_group$mean[3] - inner_group$mean[2] + inner_group$mean[4]
    
    n_reps <- nrow(data_grouped) / 4
    ssy <- sum(data_grouped_extended$value^2)
    sse <- ssy - (n_reps*4*((sum_effect/4)^2 + (effectLang/4)^2 + (effectProt/4)^2 + (effectInt/4)^2))
    ss0 <- n_reps*4*((sum_effect/4)^2)
    sst <- ssy - ss0
    ssl <- n_reps*4*((effectLang/4)^2)
    ssp <- n_reps*4*((effectProt/4)^2)
    sslp <- n_reps*4*((effectInt/4)^2)
    
    langInfluence <- ssl/sst*100
    protInfluence <- ssp/sst*100
    intInfluence <- sslp/sst*100
    errorInfluence <- 100 - (langInfluence + protInfluence + intInfluence)
    
    cat("Sum effect:", sum_effect, "\n")
    cat("Language effect:", effectLang, "\n")
    cat("Protocol effect:", effectProt, "\n")
    cat("Interaction effect:", effectInt, "\n")
    cat("\nInfluence (%):\n")
    cat("  Language:", langInfluence, "%\n")
    cat("  Protocol:", protInfluence, "%\n")
    cat("  Interaction:", intInfluence, "%\n")
    cat("  Error:", errorInfluence, "%\n")
  }
  
  cat("\n--- Descriptive Statistics ---\n")
  mean_javahttp <- mean(javahttp$value, na.rm = TRUE)
  mean_javagrpc <- mean(javagrpc$value, na.rm = TRUE)
  mean_gohttp <- mean(gohttp$value, na.rm = TRUE)
  mean_gogrpc <- mean(gogrpc$value, na.rm = TRUE)
  
  median_javahttp <- median(javahttp$value, na.rm = TRUE)
  median_javagrpc <- median(javagrpc$value, na.rm = TRUE)
  median_gohttp <- median(gohttp$value, na.rm = TRUE)
  median_gogrpc <- median(gogrpc$value, na.rm = TRUE)
  
  stddev_javahttp <- sd(javahttp$value, na.rm = TRUE)
  stddev_javagrpc <- sd(javagrpc$value, na.rm = TRUE)
  stddev_gohttp <- sd(gohttp$value, na.rm = TRUE)
  stddev_gogrpc <- sd(gogrpc$value, na.rm = TRUE)
  
  cat("Means:\n")
  cat("  Java HTTP:", mean_javahttp, "\n")
  cat("  Java gRPC:", mean_javagrpc, "\n")
  cat("  Go HTTP:", mean_gohttp, "\n")
  cat("  Go gRPC:", mean_gogrpc, "\n")
  
  cat("\nStandard Deviations:\n")
  cat("  Java HTTP:", stddev_javahttp, "\n")
  cat("  Java gRPC:", stddev_javagrpc, "\n")
  cat("  Go HTTP:", stddev_gohttp, "\n")
  cat("  Go gRPC:", stddev_gogrpc, "\n")
  
  cat("\n--- Statistical Tests ---\n")
  
  cat("Wilcoxon tests:\n")
  if (nrow(javahttp) > 0 && nrow(javagrpc) > 0) {
    wt1 <- wilcox.test(javahttp$value, javagrpc$value, paired = FALSE)
    cat("  Java HTTP vs Java gRPC: p =", wt1$p.value, "\n")
  }
  if (nrow(javahttp) > 0 && nrow(gohttp) > 0) {
    wt2 <- wilcox.test(javahttp$value, gohttp$value, paired = FALSE)
    cat("  Java HTTP vs Go HTTP: p =", wt2$p.value, "\n")
  }
  if (nrow(javahttp) > 0 && nrow(gogrpc) > 0) {
    wt3 <- wilcox.test(javahttp$value, gogrpc$value, paired = FALSE)
    cat("  Java HTTP vs Go gRPC: p =", wt3$p.value, "\n")
  }
  if (nrow(javagrpc) > 0 && nrow(gohttp) > 0) {
    wt4 <- wilcox.test(javagrpc$value, gohttp$value, paired = FALSE)
    cat("  Java gRPC vs Go HTTP: p =", wt4$p.value, "\n")
  }
  if (nrow(javagrpc) > 0 && nrow(gogrpc) > 0) {
    wt5 <- wilcox.test(javagrpc$value, gogrpc$value, paired = FALSE)
    cat("  Java gRPC vs Go gRPC: p =", wt5$p.value, "\n")
  }
  if (nrow(gohttp) > 0 && nrow(gogrpc) > 0) {
    wt6 <- wilcox.test(gohttp$value, gogrpc$value, paired = FALSE)
    cat("  Go HTTP vs Go gRPC: p =", wt6$p.value, "\n")
  }
  
  cat("\nKruskal-Wallis tests:\n")
  kw1 <- kruskal.test(value ~ protocol, data = data_filtered)
  cat("  Protocol: p =", kw1$p.value, "\n")
  kw2 <- kruskal.test(value ~ language, data = data_filtered)
  cat("  Language: p =", kw2$p.value, "\n")
  data_filtered$combined_factor <- interaction(data_filtered$protocol, data_filtered$language)
  kw3 <- kruskal.test(value ~ combined_factor, data = data_filtered)
  cat("  Combined: p =", kw3$p.value, "\n")
  
  cat("\n--- Normality Tests ---\n")
  if (nrow(javahttp) > 3 && nrow(javahttp) <= 5000) {
    sh1 <- shapiro.test(javahttp$value)
    cat("  Java HTTP: p =", sh1$p.value, "\n")
  }
  if (nrow(javagrpc) > 3 && nrow(javagrpc) <= 5000) {
    sh2 <- shapiro.test(javagrpc$value)
    cat("  Java gRPC: p =", sh2$p.value, "\n")
  }
  if (nrow(gohttp) > 3 && nrow(gohttp) <= 5000) {
    sh3 <- shapiro.test(gohttp$value)
    cat("  Go HTTP: p =", sh3$p.value, "\n")
  }
  if (nrow(gogrpc) > 3 && nrow(gogrpc) <= 5000) {
    sh4 <- shapiro.test(gogrpc$value)
    cat("  Go gRPC: p =", sh4$p.value, "\n")
  }
  
  cat("\n--- Creating Graphics ---\n")
  
  dev.new()
  par(mfrow = c(2, 2), mar = c(4, 4, 3, 2))
  
  boxplot(value ~ app_name, data = data_filtered, col = "lightblue", 
          main = paste("Boxplot - Payload", ps),
          xlab = "Aplicação", ylab = "Valor da Requisição",
          cex.lab = 1.0, cex.main = 1.1, cex.axis = 0.9)
  
  hist(javahttp$value, breaks = "Sturges", main = paste("Java REST - Payload", ps),
       xlab = "Value", ylab = "Frequency", cex.lab = 1.0, cex.main = 1.1, cex.axis = 0.9)
  
  hist(javagrpc$value, breaks = "Sturges", main = paste("Java gRPC - Payload", ps),
       xlab = "Value", ylab = "Frequency", cex.lab = 1.0, cex.main = 1.1, cex.axis = 0.9)
  
  hist(gohttp$value, breaks = "Sturges", main = paste("Go REST - Payload", ps),
       xlab = "Value", ylab = "Frequency", cex.lab = 1.0, cex.main = 1.1, cex.axis = 0.9)
  
  dev.new()
  par(mfrow = c(2, 2), mar = c(4, 4, 3, 2))
  
  qqnorm(javahttp$value, main = paste("Q-Q Java REST - Payload", ps), cex.main = 1.1, cex.axis = 0.9)
  qqline(javahttp$value, col = "red")
  
  qqnorm(javagrpc$value, main = paste("Q-Q Java gRPC - Payload", ps), cex.main = 1.1, cex.axis = 0.9)
  qqline(javagrpc$value, col = "red")
  
  qqnorm(gohttp$value, main = paste("Q-Q Go REST - Payload", ps), cex.main = 1.1, cex.axis = 0.9)
  qqline(gohttp$value, col = "red")
  
  qqnorm(gogrpc$value, main = paste("Q-Q Go gRPC - Payload", ps), cex.main = 1.1, cex.axis = 0.9)
  qqline(gogrpc$value, col = "red")
  
  png(sprintf("boxplot_payload_%d.png", ps), width = 1200, height = 800, res = 150)
  par(mfrow = c(2, 2), mar = c(4, 4, 3, 2))
  boxplot(value ~ app_name, data = data_filtered, col = "lightblue", 
          main = paste("Boxplot - Payload", ps),
          xlab = "Aplicação", ylab = "Valor da Requisição",
          cex.lab = 1.0, cex.main = 1.1, cex.axis = 0.9)
  hist(javahttp$value, breaks = "Sturges", main = paste("Java REST - Payload", ps),
       xlab = "Value", ylab = "Frequency", cex.lab = 1.0, cex.main = 1.1, cex.axis = 0.9)
  hist(javagrpc$value, breaks = "Sturges", main = paste("Java gRPC - Payload", ps),
       xlab = "Value", ylab = "Frequency", cex.lab = 1.0, cex.main = 1.1, cex.axis = 0.9)
  hist(gohttp$value, breaks = "Sturges", main = paste("Go REST - Payload", ps),
       xlab = "Value", ylab = "Frequency", cex.lab = 1.0, cex.main = 1.1, cex.axis = 0.9)
  dev.off()
  
  png(sprintf("qqplot_payload_%d.png", ps), width = 1200, height = 800, res = 150)
  par(mfrow = c(2, 2), mar = c(4, 4, 3, 2))
  qqnorm(javahttp$value, main = paste("Q-Q Java REST - Payload", ps), cex.main = 1.1, cex.axis = 0.9)
  qqline(javahttp$value, col = "red")
  qqnorm(javagrpc$value, main = paste("Q-Q Java gRPC - Payload", ps), cex.main = 1.1, cex.axis = 0.9)
  qqline(javagrpc$value, col = "red")
  qqnorm(gohttp$value, main = paste("Q-Q Go REST - Payload", ps), cex.main = 1.1, cex.axis = 0.9)
  qqline(gohttp$value, col = "red")
  qqnorm(gogrpc$value, main = paste("Q-Q Go gRPC - Payload", ps), cex.main = 1.1, cex.axis = 0.9)
  qqline(gogrpc$value, col = "red")
  dev.off()
  
  cat("Saved: boxplot_payload_", ps, ".png, qqplot_payload_", ps, ".png\n", sep = "")
}

cat("\n", rep("=", 60), "\n")
cat("OVERALL ANALYSIS ACROSS ALL PAYLOAD SIZES\n")
cat(rep("=", 60), "\n\n")

data_all <- data %>%
  remover_outliers("value")

data_all_filtered <- data_all %>%
  filter(!is.na(language), !is.na(protocol))

cat("--- Overall Boxplot ---\n")
dev.new()
boxplot(value ~ app_name, data = data_all_filtered, col = "lightblue", 
        main = "Boxplot - All Payload Sizes",
        xlab = "Aplicação", ylab = "Valor da Requisição",
        cex.lab = 1.0, cex.main = 1.1, cex.axis = 0.9)

png("boxplot_all_payloads.png", width = 1200, height = 800, res = 150)
boxplot(value ~ app_name, data = data_all_filtered, col = "lightblue", 
        main = "Boxplot - All Payload Sizes",
        xlab = "Aplicação", ylab = "Valor da Requisição",
        cex.lab = 1.0, cex.main = 1.1, cex.axis = 0.9)
dev.off()

cat("--- Performance by Payload Size ---\n")

cat("Testing normality for each app across all payload sizes...\n")
normality_results <- data_all_filtered %>%
  group_by(app_name) %>%
  summarise(
    shapiro_p = if(n() > 3) {
      sample_data <- if(n() > 5000) sample(value, 5000) else value
      tryCatch(shapiro.test(sample_data)$p.value, error = function(e) NA)
    } else NA,
    is_normal = if(!is.na(shapiro_p)) shapiro_p > 0.05 else FALSE,
    .groups = "drop"
  )

cat("Normality results (p > 0.05 = normal):\n")
for (i in 1:nrow(normality_results)) {
  cat("  ", normality_results$app_name[i], ": p =", 
      if(is.na(normality_results$shapiro_p[i])) "N/A" else normality_results$shapiro_p[i],
      "-", if(normality_results$is_normal[i]) "NORMAL" else "NOT NORMAL", "\n")
}

use_median <- !all(normality_results$is_normal, na.rm = TRUE)
cat("\nUsing", if(use_median) "MEDIAN" else "MEAN", "for summary statistics\n\n")

dev.new()
par(mfrow = c(2, 2), mar = c(4, 4, 3, 2))

if (use_median) {
  data_summary <- data_all_filtered %>%
    group_by(payload_size, app_name) %>%
    summarise(
      central_value = median(value, na.rm = TRUE),
      q25 = quantile(value, 0.25, na.rm = TRUE),
      q75 = quantile(value, 0.75, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(payload_size)
} else {
  data_summary <- data_all_filtered %>%
    group_by(payload_size, app_name) %>%
    summarise(
      central_value = mean(value, na.rm = TRUE),
      se_value = sd(value, na.rm = TRUE) / sqrt(n()),
      .groups = "drop"
    ) %>%
    arrange(payload_size)
}

javahttp_summary <- data_summary %>% filter(app_name == "javahttp")
javagrpc_summary <- data_summary %>% filter(app_name == "javagrpc")
gohttp_summary <- data_summary %>% filter(app_name == "gohttp")
gogrpc_summary <- data_summary %>% filter(app_name == "gogrpc")

ylabel <- if(use_median) "Median Latency (seconds)" else "Mean Latency (seconds)"

plot(javahttp_summary$payload_size, javahttp_summary$central_value, 
     type = "b", col = "blue", lwd = 2, pch = 19, cex = 0.8,
     xlab = "Payload Size", ylab = ylabel,
     main = "Java REST Performance", cex.lab = 1.0, cex.main = 1.1, cex.axis = 0.9)
if (use_median && "q25" %in% names(javahttp_summary)) {
  arrows(javahttp_summary$payload_size, javahttp_summary$q25,
         javahttp_summary$payload_size, javahttp_summary$q75,
         length = 0.05, angle = 90, code = 3, col = "blue", lwd = 1)
}
grid()

plot(javagrpc_summary$payload_size, javagrpc_summary$central_value, 
     type = "b", col = "red", lwd = 2, pch = 19, cex = 0.8,
     xlab = "Payload Size", ylab = ylabel,
     main = "Java gRPC Performance", cex.lab = 1.0, cex.main = 1.1, cex.axis = 0.9)
if (use_median && "q25" %in% names(javagrpc_summary)) {
  arrows(javagrpc_summary$payload_size, javagrpc_summary$q25,
         javagrpc_summary$payload_size, javagrpc_summary$q75,
         length = 0.05, angle = 90, code = 3, col = "red", lwd = 1)
}
grid()

plot(gohttp_summary$payload_size, gohttp_summary$central_value, 
     type = "b", col = "darkgreen", lwd = 2, pch = 19, cex = 0.8,
     xlab = "Payload Size", ylab = ylabel,
     main = "Go REST Performance", cex.lab = 1.0, cex.main = 1.1, cex.axis = 0.9)
if (use_median && "q25" %in% names(gohttp_summary)) {
  arrows(gohttp_summary$payload_size, gohttp_summary$q25,
         gohttp_summary$payload_size, gohttp_summary$q75,
         length = 0.05, angle = 90, code = 3, col = "darkgreen", lwd = 1)
}
grid()

plot(gogrpc_summary$payload_size, gogrpc_summary$central_value, 
     type = "b", col = "orange", lwd = 2, pch = 19, cex = 0.8,
     xlab = "Payload Size", ylab = ylabel,
     main = "Go gRPC Performance", cex.lab = 1.0, cex.main = 1.1, cex.axis = 0.9)
if (use_median && "q25" %in% names(gogrpc_summary)) {
  arrows(gogrpc_summary$payload_size, gogrpc_summary$q25,
         gogrpc_summary$payload_size, gogrpc_summary$q75,
         length = 0.05, angle = 90, code = 3, col = "orange", lwd = 1)
}
grid()

png("performance_by_payload.png", width = 1600, height = 1200, res = 150)
par(mfrow = c(2, 2), mar = c(4, 4, 3, 2))
plot(javahttp_summary$payload_size, javahttp_summary$central_value, 
     type = "b", col = "blue", lwd = 2, pch = 19, cex = 0.8,
     xlab = "Payload Size", ylab = ylabel,
     main = "Java REST Performance", cex.lab = 1.0, cex.main = 1.1, cex.axis = 0.9)
if (use_median && "q25" %in% names(javahttp_summary)) {
  arrows(javahttp_summary$payload_size, javahttp_summary$q25,
         javahttp_summary$payload_size, javahttp_summary$q75,
         length = 0.05, angle = 90, code = 3, col = "blue", lwd = 1)
}
grid()
plot(javagrpc_summary$payload_size, javagrpc_summary$central_value, 
     type = "b", col = "red", lwd = 2, pch = 19, cex = 0.8,
     xlab = "Payload Size", ylab = ylabel,
     main = "Java gRPC Performance", cex.lab = 1.0, cex.main = 1.1, cex.axis = 0.9)
if (use_median && "q25" %in% names(javagrpc_summary)) {
  arrows(javagrpc_summary$payload_size, javagrpc_summary$q25,
         javagrpc_summary$payload_size, javagrpc_summary$q75,
         length = 0.05, angle = 90, code = 3, col = "red", lwd = 1)
}
grid()
plot(gohttp_summary$payload_size, gohttp_summary$central_value, 
     type = "b", col = "darkgreen", lwd = 2, pch = 19, cex = 0.8,
     xlab = "Payload Size", ylab = ylabel,
     main = "Go REST Performance", cex.lab = 1.0, cex.main = 1.1, cex.axis = 0.9)
if (use_median && "q25" %in% names(gohttp_summary)) {
  arrows(gohttp_summary$payload_size, gohttp_summary$q25,
         gohttp_summary$payload_size, gohttp_summary$q75,
         length = 0.05, angle = 90, code = 3, col = "darkgreen", lwd = 1)
}
grid()
plot(gogrpc_summary$payload_size, gogrpc_summary$central_value, 
     type = "b", col = "orange", lwd = 2, pch = 19, cex = 0.8,
     xlab = "Payload Size", ylab = ylabel,
     main = "Go gRPC Performance", cex.lab = 1.0, cex.main = 1.1, cex.axis = 0.9)
if (use_median && "q25" %in% names(gogrpc_summary)) {
  arrows(gogrpc_summary$payload_size, gogrpc_summary$q25,
         gogrpc_summary$payload_size, gogrpc_summary$q75,
         length = 0.05, angle = 90, code = 3, col = "orange", lwd = 1)
}
grid()
dev.off()

cat("Saved: boxplot_all_payloads.png, performance_by_payload.png\n")

cat("\n--- Line Chart: All Applications ---\n")
dev.new()
par(mar = c(5, 5, 4, 2))

plot(javahttp_summary$payload_size, javahttp_summary$central_value, 
     type = "b", col = "blue", lwd = 2.5, pch = 19, cex = 1.0,
     xlab = "Tamanho da Requisição (número de inteiros)", 
     ylab = ylabel,
     main = "Desempenho por Tamanho de Requisição",
     cex.lab = 1.1, cex.main = 1.2, cex.axis = 1.0,
     ylim = range(c(javahttp_summary$central_value, javagrpc_summary$central_value,
                     gohttp_summary$central_value, gogrpc_summary$central_value), na.rm = TRUE))

lines(javagrpc_summary$payload_size, javagrpc_summary$central_value, 
      type = "b", col = "red", lwd = 2.5, pch = 17, cex = 1.0)

lines(gohttp_summary$payload_size, gohttp_summary$central_value, 
      type = "b", col = "darkgreen", lwd = 2.5, pch = 15, cex = 1.0)

lines(gogrpc_summary$payload_size, gogrpc_summary$central_value, 
      type = "b", col = "orange", lwd = 2.5, pch = 18, cex = 1.0)

if (use_median && "q25" %in% names(javahttp_summary)) {
  arrows(javahttp_summary$payload_size, javahttp_summary$q25,
         javahttp_summary$payload_size, javahttp_summary$q75,
         length = 0.03, angle = 90, code = 3, col = "blue", lwd = 1, alpha = 0.3)
  arrows(javagrpc_summary$payload_size, javagrpc_summary$q25,
         javagrpc_summary$payload_size, javagrpc_summary$q75,
         length = 0.03, angle = 90, code = 3, col = "red", lwd = 1, alpha = 0.3)
  arrows(gohttp_summary$payload_size, gohttp_summary$q25,
         gohttp_summary$payload_size, gohttp_summary$q75,
         length = 0.03, angle = 90, code = 3, col = "darkgreen", lwd = 1, alpha = 0.3)
  arrows(gogrpc_summary$payload_size, gogrpc_summary$q25,
         gogrpc_summary$payload_size, gogrpc_summary$q75,
         length = 0.03, angle = 90, code = 3, col = "orange", lwd = 1, alpha = 0.3)
}

legend("topleft", 
       legend = c("Java REST", "Java gRPC", "Go REST", "Go gRPC"),
       col = c("blue", "red", "darkgreen", "orange"),
       lty = 1, lwd = 2.5, pch = c(19, 17, 15, 18),
       cex = 1.0)

grid()

png("line_chart_all_apps.png", width = 1600, height = 1000, res = 150)
par(mar = c(5, 5, 4, 2))

plot(javahttp_summary$payload_size, javahttp_summary$central_value, 
     type = "b", col = "blue", lwd = 2.5, pch = 19, cex = 1.0,
     xlab = "Tamanho da Requisição (número de inteiros)", 
     ylab = ylabel,
     main = "Desempenho por Tamanho de Requisição",
     cex.lab = 1.1, cex.main = 1.2, cex.axis = 1.0,
     ylim = range(c(javahttp_summary$central_value, javagrpc_summary$central_value,
                     gohttp_summary$central_value, gogrpc_summary$central_value), na.rm = TRUE))

lines(javagrpc_summary$payload_size, javagrpc_summary$central_value, 
      type = "b", col = "red", lwd = 2.5, pch = 17, cex = 1.0)

lines(gohttp_summary$payload_size, gohttp_summary$central_value, 
      type = "b", col = "darkgreen", lwd = 2.5, pch = 15, cex = 1.0)

lines(gogrpc_summary$payload_size, gogrpc_summary$central_value, 
      type = "b", col = "orange", lwd = 2.5, pch = 18, cex = 1.0)

if (use_median && "q25" %in% names(javahttp_summary)) {
  arrows(javahttp_summary$payload_size, javahttp_summary$q25,
         javahttp_summary$payload_size, javahttp_summary$q75,
         length = 0.03, angle = 90, code = 3, col = "blue", lwd = 1)
  arrows(javagrpc_summary$payload_size, javagrpc_summary$q25,
         javagrpc_summary$payload_size, javagrpc_summary$q75,
         length = 0.03, angle = 90, code = 3, col = "red", lwd = 1)
  arrows(gohttp_summary$payload_size, gohttp_summary$q25,
         gohttp_summary$payload_size, gohttp_summary$q75,
         length = 0.03, angle = 90, code = 3, col = "darkgreen", lwd = 1)
  arrows(gogrpc_summary$payload_size, gogrpc_summary$q25,
         gogrpc_summary$payload_size, gogrpc_summary$q75,
         length = 0.03, angle = 90, code = 3, col = "orange", lwd = 1)
}

legend("topleft", 
       legend = c("Java REST", "Java gRPC", "Go REST", "Go gRPC"),
       col = c("blue", "red", "darkgreen", "orange"),
       lty = 1, lwd = 2.5, pch = c(19, 17, 15, 18),
       cex = 1.0)

grid()
dev.off()

cat("Saved: line_chart_all_apps.png\n")

cat("\nAnalysis complete!\n")
