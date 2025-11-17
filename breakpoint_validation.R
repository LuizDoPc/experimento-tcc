library(tidyverse)
library(readr)
library(boot)

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

calculateBreakpoint <- function(data_subset) {
  data_summary <- data_subset %>%
    group_by(payload_size, protocol) %>%
    summarise(
      mean_latency = mean(value, na.rm = TRUE),
      .groups = "drop"
    )
  
  http_data <- data_summary %>%
    filter(protocol == "http") %>%
    arrange(payload_size)
  
  grpc_data <- data_summary %>%
    filter(protocol == "grpc") %>%
    arrange(payload_size)
  
  data_diff <- http_data %>%
    inner_join(grpc_data, by = "payload_size", suffix = c("_http", "_grpc")) %>%
    mutate(diff = mean_latency_http - mean_latency_grpc) %>%
    select(payload_size, diff)
  
  if (nrow(data_diff) < 5) {
    return(NA)
  }
  
  model_linear <- lm(diff ~ payload_size, data = data_diff)
  
  initial_breakpoint <- median(data_diff$payload_size)
  
  tryCatch({
    library(segmented)
    seg_model <- segmented(model_linear, seg.Z = ~payload_size, 
                          psi = list(payload_size = initial_breakpoint))
    return(seg_model$psi[1, 2])
  }, error = function(e) {
    return(NA)
  })
}

bootstrapBreakpoint <- function(data, lang, n_bootstrap = 1000) {
  cat(sprintf("\n=== Bootstrap Validation: %s ===\n", lang))
  
  data_filtered <- data %>%
    filter(language == lang) %>%
    remover_outliers("value")
  
  data_grouped <- data_filtered %>%
    group_by(payload_size, protocol, experiment_id) %>%
    summarise(
      mean_latency = mean(value, na.rm = TRUE),
      .groups = "drop"
    )
  
  breakpoint_original <- calculateBreakpoint(data_grouped)
  
  if (is.na(breakpoint_original)) {
    cat("Cannot calculate original breakpoint\n")
    return(NULL)
  }
  
  cat(sprintf("Original breakpoint estimate: %.0f integers\n", breakpoint_original))
  cat(sprintf("Running %d bootstrap iterations...\n", n_bootstrap))
  
  bootstrap_breakpoints <- numeric(n_bootstrap)
  
  unique_experiments <- unique(data_grouped$experiment_id)
  
  for (i in 1:n_bootstrap) {
    if (i %% 100 == 0) {
      cat(sprintf("  Iteration %d/%d\n", i, n_bootstrap))
    }
    
    sampled_experiments <- sample(unique_experiments, 
                                  size = length(unique_experiments), 
                                  replace = TRUE)
    
    bootstrap_data <- data_grouped %>%
      filter(experiment_id %in% sampled_experiments)
    
    breakpoint_boot <- calculateBreakpoint(bootstrap_data)
    bootstrap_breakpoints[i] <- breakpoint_boot
  }
  
  bootstrap_breakpoints <- bootstrap_breakpoints[!is.na(bootstrap_breakpoints)]
  
  if (length(bootstrap_breakpoints) < 100) {
    cat("Warning: Too few successful bootstrap iterations\n")
    return(NULL)
  }
  
  bootstrap_mean <- mean(bootstrap_breakpoints)
  bootstrap_median <- median(bootstrap_breakpoints)
  bootstrap_sd <- sd(bootstrap_breakpoints)
  bootstrap_ci <- quantile(bootstrap_breakpoints, c(0.025, 0.975))
  
  cat("\nBootstrap Results:\n")
  cat(sprintf("  Mean: %.0f integers\n", bootstrap_mean))
  cat(sprintf("  Median: %.0f integers\n", bootstrap_median))
  cat(sprintf("  SD: %.2f\n", bootstrap_sd))
  cat(sprintf("  95%% CI: [%.0f, %.0f]\n", bootstrap_ci[1], bootstrap_ci[2]))
  cat(sprintf("  Bias: %.2f\n", bootstrap_mean - breakpoint_original))
  
  png(sprintf("bootstrap_validation_%s.png", lang), 
      width = 1200, height = 600, res = 150)
  par(mfrow = c(1, 2))
  
  hist(bootstrap_breakpoints,
       main = sprintf("Bootstrap Distribution: %s", lang),
       xlab = "Breakpoint (number of integers)",
       breaks = 30,
       col = "lightblue")
  abline(v = breakpoint_original, col = "red", lwd = 2, lty = 2)
  abline(v = bootstrap_mean, col = "blue", lwd = 2)
  abline(v = bootstrap_ci, col = "green", lty = 3)
  legend("topright",
         legend = c("Original", "Bootstrap Mean", "95% CI"),
         col = c("red", "blue", "green"),
         lty = c(2, 1, 3),
         lwd = c(2, 2, 1))
  
  qqnorm(bootstrap_breakpoints,
         main = sprintf("Q-Q Plot: %s", lang))
  qqline(bootstrap_breakpoints, col = "red")
  
  dev.off()
  
  cat(sprintf("\nPlot saved: bootstrap_validation_%s.png\n", lang))
  
  return(list(
    original = breakpoint_original,
    bootstrap_mean = bootstrap_mean,
    bootstrap_median = bootstrap_median,
    bootstrap_sd = bootstrap_sd,
    bootstrap_ci = bootstrap_ci,
    bootstrap_values = bootstrap_breakpoints
  ))
}

sensitivityAnalysis <- function(data, lang) {
  cat(sprintf("\n=== Sensitivity Analysis: %s ===\n", lang))
  
  iqr_multipliers <- c(1.5, 2.0, 2.5, 3.0, 3.5, 4.0)
  breakpoints_sensitivity <- numeric(length(iqr_multipliers))
  
  for (i in seq_along(iqr_multipliers)) {
    mult <- iqr_multipliers[i]
    
    remover_outliers_custom <- function(dados, campo) {
      Q1 <- quantile(dados[[campo]], 0.25, na.rm = TRUE)
      Q3 <- quantile(dados[[campo]], 0.75, na.rm = TRUE)
      IQR <- Q3 - Q1
      
      limite_inferior <- Q1 - mult * IQR
      limite_superior <- Q3 + mult * IQR
      
      dados_filtrados <- dados[dados[[campo]] >= limite_inferior & dados[[campo]] <= limite_superior, ]
      
      return(dados_filtrados)
    }
    
    data_filtered <- data %>%
      filter(language == lang) %>%
      remover_outliers_custom("value")
    
    data_grouped <- data_filtered %>%
      group_by(payload_size, protocol, experiment_id) %>%
      summarise(
        mean_latency = mean(value, na.rm = TRUE),
        .groups = "drop"
      )
    
    breakpoint_sens <- calculateBreakpoint(data_grouped)
    breakpoints_sensitivity[i] <- breakpoint_sens
    
    cat(sprintf("IQR multiplier %.1f: Breakpoint = %.0f\n", mult, breakpoint_sens))
  }
  
  sensitivity_df <- data.frame(
    iqr_multiplier = iqr_multipliers,
    breakpoint = breakpoints_sensitivity
  )
  
  png(sprintf("sensitivity_analysis_%s.png", lang),
      width = 1000, height = 600, res = 150)
  
  plot(sensitivity_df$iqr_multiplier, sensitivity_df$breakpoint,
       type = "b",
       xlab = "IQR Multiplier for Outlier Removal",
       ylab = "Breakpoint Estimate (number of integers)",
       main = sprintf("Sensitivity Analysis: %s", lang),
       pch = 19, col = "blue")
  grid()
  
  dev.off()
  
  cat(sprintf("\nPlot saved: sensitivity_analysis_%s.png\n", lang))
  
  return(sensitivity_df)
}

results_go_bootstrap <- bootstrapBreakpoint(data, "go")
results_java_bootstrap <- bootstrapBreakpoint(data, "java")

sensitivity_go <- sensitivityAnalysis(data, "go")
sensitivity_java <- sensitivityAnalysis(data, "java")

cat("\n=== Validation Summary ===\n")

cat("\nGo - Bootstrap Validation:\n")
if (!is.null(results_go_bootstrap)) {
  cat(sprintf("  Original: %.0f\n", results_go_bootstrap$original))
  cat(sprintf("  Bootstrap Mean: %.0f\n", results_go_bootstrap$bootstrap_mean))
  cat(sprintf("  Bootstrap 95%% CI: [%.0f, %.0f]\n", 
              results_go_bootstrap$bootstrap_ci[1], 
              results_go_bootstrap$bootstrap_ci[2]))
  cat(sprintf("  Coefficient of Variation: %.2f%%\n", 
              100 * results_go_bootstrap$bootstrap_sd / results_go_bootstrap$bootstrap_mean))
}

cat("\nJava - Bootstrap Validation:\n")
if (!is.null(results_java_bootstrap)) {
  cat(sprintf("  Original: %.0f\n", results_java_bootstrap$original))
  cat(sprintf("  Bootstrap Mean: %.0f\n", results_java_bootstrap$bootstrap_mean))
  cat(sprintf("  Bootstrap 95%% CI: [%.0f, %.0f]\n", 
              results_java_bootstrap$bootstrap_ci[1], 
              results_java_bootstrap$bootstrap_ci[2]))
  cat(sprintf("  Coefficient of Variation: %.2f%%\n", 
              100 * results_java_bootstrap$bootstrap_sd / results_java_bootstrap$bootstrap_mean))
}

cat("\nSensitivity Analysis Summary:\n")
cat("Go - Breakpoint range across IQR multipliers:\n")
cat(sprintf("  Min: %.0f, Max: %.0f, Range: %.0f\n",
            min(sensitivity_go$breakpoint, na.rm = TRUE),
            max(sensitivity_go$breakpoint, na.rm = TRUE),
            max(sensitivity_go$breakpoint, na.rm = TRUE) - min(sensitivity_go$breakpoint, na.rm = TRUE)))

cat("Java - Breakpoint range across IQR multipliers:\n")
cat(sprintf("  Min: %.0f, Max: %.0f, Range: %.0f\n",
            min(sensitivity_java$breakpoint, na.rm = TRUE),
            max(sensitivity_java$breakpoint, na.rm = TRUE),
            max(sensitivity_java$breakpoint, na.rm = TRUE) - min(sensitivity_java$breakpoint, na.rm = TRUE)))


