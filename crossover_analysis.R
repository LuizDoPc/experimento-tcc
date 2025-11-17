library(tidyverse)
library(readr)
library(lme4)

database <- read_csv("dados/experimento_all_sizes.csv")

data <- database %>%
  mutate(
    language = stringr::str_extract(app_name, "java|go"),
    protocol = stringr::str_extract(app_name, "http|grpc"),
    payload_size = as.numeric(request_size)
  )

data$language <- as.factor(data$language)
data$protocol <- as.factor(data$protocol)

remover_outliers <- function(dados, campo) {
  Q1 <- quantile(dados[[campo]], 0.25, na.rm = TRUE)
  Q3 <- quantile(dados[[campo]], 0.75, na.rm = TRUE)
  IQR <- Q3 - Q1
  
  limite_inferior <- Q1 - 3.5 * IQR
  limite_superior <- Q3 + 3.5 * IQR
  
  dados_filtrados <- dados[dados[[campo]] >= limite_inferior & dados[[campo]] <= limite_superior, ]
  
  return(dados_filtrados)
}

analyzeCrossover <- function(data, lang) {
  cat(sprintf("\n=== Crossover Analysis: %s ===\n", lang))
  
  data_filtered <- data %>%
    filter(language == lang) %>%
    remover_outliers("value")
  
  data_filtered$payload_size_centered <- data_filtered$payload_size - mean(data_filtered$payload_size, na.rm = TRUE)
  
  cat("\n--- Linear Model with Interaction ---\n")
  
  model_interaction <- lm(value ~ protocol * payload_size_centered, 
                         data = data_filtered)
  
  cat("Model summary:\n")
  print(summary(model_interaction))
  
  intercept_http <- coef(model_interaction)["(Intercept)"]
  intercept_grpc <- coef(model_interaction)["(Intercept)"] + coef(model_interaction)["protocolgrpc"]
  slope_http <- coef(model_interaction)["payload_size_centered"]
  slope_grpc <- coef(model_interaction)["payload_size_centered"] + coef(model_interaction)["protocolgrpc:payload_size_centered"]
  
  cat("\n--- Protocol-specific parameters ---\n")
  cat(sprintf("HTTP - Intercept: %.6f, Slope: %.9f\n", intercept_http, slope_http))
  cat(sprintf("gRPC - Intercept: %.6f, Slope: %.9f\n", intercept_grpc, slope_grpc))
  
  if (abs(slope_http - slope_grpc) > 1e-10) {
    crossover_point_centered <- (intercept_grpc - intercept_http) / (slope_http - slope_grpc)
    crossover_point <- crossover_point_centered + mean(data_filtered$payload_size, na.rm = TRUE)
    
    cat(sprintf("\nCrossover point (centered): %.2f\n", crossover_point_centered))
    cat(sprintf("Crossover point (actual): %.0f integers\n", crossover_point))
    
    vcov_matrix <- vcov(model_interaction)
    
    intercept_diff <- intercept_grpc - intercept_http
    slope_diff <- slope_http - slope_grpc
    
    var_crossover <- (1/slope_diff^2) * (
      vcov_matrix["(Intercept)", "(Intercept)"] + 
      vcov_matrix["protocolgrpc", "protocolgrpc"] +
      2 * vcov_matrix["(Intercept)", "protocolgrpc"] +
      crossover_point_centered^2 * (
        vcov_matrix["payload_size_centered", "payload_size_centered"] +
        vcov_matrix["protocolgrpc:payload_size_centered", "protocolgrpc:payload_size_centered"] +
        2 * vcov_matrix["payload_size_centered", "protocolgrpc:payload_size_centered"]
      ) +
      2 * crossover_point_centered * (
        vcov_matrix["(Intercept)", "payload_size_centered"] +
        vcov_matrix["protocolgrpc", "payload_size_centered"] +
        vcov_matrix["(Intercept)", "protocolgrpc:payload_size_centered"] +
        vcov_matrix["protocolgrpc", "protocolgrpc:payload_size_centered"]
      )
    )
    
    se_crossover <- sqrt(var_crossover)
    ci_lower <- crossover_point - 1.96 * se_crossover
    ci_upper <- crossover_point + 1.96 * se_crossover
    
    cat(sprintf("Standard error: %.2f\n", se_crossover))
    cat(sprintf("95%% Confidence Interval: [%.0f, %.0f]\n", ci_lower, ci_upper))
  } else {
    cat("\nSlopes are parallel - no crossover point\n")
    crossover_point <- NA
    ci_lower <- NA
    ci_upper <- NA
  }
  
  cat("\n--- Quadratic Model with Interaction ---\n")
  
  model_quadratic <- lm(value ~ protocol * payload_size_centered + 
                        protocol * I(payload_size_centered^2), 
                       data = data_filtered)
  
  cat("Quadratic model summary:\n")
  print(summary(model_quadratic))
  
  data_summary <- data_filtered %>%
    group_by(payload_size, protocol) %>%
    summarise(
      mean_latency = mean(value, na.rm = TRUE),
      se_latency = sd(value, na.rm = TRUE) / sqrt(n()),
      .groups = "drop"
    )
  
  payload_range <- seq(min(data_summary$payload_size), 
                       max(data_summary$payload_size), 
                       length.out = 100)
  payload_centered <- payload_range - mean(data_filtered$payload_size, na.rm = TRUE)
  
  pred_data <- expand_grid(
    payload_size = payload_range,
    payload_size_centered = payload_centered,
    protocol = levels(data_filtered$protocol)
  )
  
  pred_data$predicted <- predict(model_interaction, newdata = pred_data)
  pred_data$predicted_quad <- predict(model_quadratic, newdata = pred_data)
  
  png(sprintf("crossover_%s.png", lang), width = 1400, height = 800, res = 150)
  par(mfrow = c(1, 2))
  
  plot(data_summary$payload_size, data_summary$mean_latency,
       col = ifelse(data_summary$protocol == "http", "blue", "red"),
       pch = 19,
       xlab = "Payload Size (number of integers)",
       ylab = "Mean Latency (seconds)",
       main = sprintf("Crossover Analysis: %s (Linear)", lang))
  
  http_pred <- pred_data %>% filter(protocol == "http")
  grpc_pred <- pred_data %>% filter(protocol == "grpc")
  
  lines(http_pred$payload_size, http_pred$predicted, col = "blue", lwd = 2)
  lines(grpc_pred$payload_size, grpc_pred$predicted, col = "red", lwd = 2)
  
  if (!is.na(crossover_point)) {
    abline(v = crossover_point, col = "green", lty = 2, lwd = 2)
    abline(v = ci_lower, col = "green", lty = 3)
    abline(v = ci_upper, col = "green", lty = 3)
  }
  
  legend("topleft",
         legend = c("HTTP/REST", "gRPC", if(!is.na(crossover_point)) "Crossover" else NULL),
         col = c("blue", "red", if(!is.na(crossover_point)) "green" else NULL),
         lty = c(1, 1, if(!is.na(crossover_point)) 2 else NULL),
         lwd = c(2, 2, if(!is.na(crossover_point)) 2 else NULL),
         pch = c(19, 19, if(!is.na(crossover_point)) NA else NULL))
  
  diff_data <- data_summary %>%
    pivot_wider(names_from = protocol, values_from = mean_latency) %>%
    mutate(diff = http - grpc)
  
  plot(diff_data$payload_size, diff_data$diff,
       xlab = "Payload Size (number of integers)",
       ylab = "Latency Difference (HTTP - gRPC)",
       main = sprintf("Performance Difference: %s", lang),
       pch = 19, col = "purple")
  abline(h = 0, col = "gray", lty = 2)
  
  if (!is.na(crossover_point)) {
    abline(v = crossover_point, col = "green", lty = 2, lwd = 2)
    abline(v = ci_lower, col = "green", lty = 3)
    abline(v = ci_upper, col = "green", lty = 3)
  }
  
  diff_pred <- pred_data %>%
    pivot_wider(id_cols = payload_size, 
                names_from = protocol, 
                values_from = predicted) %>%
    mutate(diff = http - grpc)
  
  lines(diff_pred$payload_size, diff_pred$diff, col = "purple", lwd = 2)
  
  dev.off()
  
  cat(sprintf("\nPlot saved: crossover_%s.png\n", lang))
  
  return(list(
    crossover_point = if(exists("crossover_point")) crossover_point else NA,
    ci_lower = if(exists("ci_lower")) ci_lower else NA,
    ci_upper = if(exists("ci_upper")) ci_upper else NA,
    model_linear = model_interaction,
    model_quadratic = model_quadratic
  ))
}

results_go <- analyzeCrossover(data, "go")
results_java <- analyzeCrossover(data, "java")

cat("\n=== Summary ===\n")
cat("\nGo - Crossover point where REST becomes better than gRPC:\n")
if (!is.na(results_go$crossover_point)) {
  cat(sprintf("  Estimate: %.0f integers\n", results_go$crossover_point))
  cat(sprintf("  95%% CI: [%.0f, %.0f]\n", results_go$ci_lower, results_go$ci_upper))
} else {
  cat("  No crossover point detected\n")
}

cat("\nJava - Crossover point where REST becomes better than gRPC:\n")
if (!is.na(results_java$crossover_point)) {
  cat(sprintf("  Estimate: %.0f integers\n", results_java$crossover_point))
  cat(sprintf("  95%% CI: [%.0f, %.0f]\n", results_java$ci_lower, results_java$ci_upper))
} else {
  cat("  No crossover point detected\n")
}


