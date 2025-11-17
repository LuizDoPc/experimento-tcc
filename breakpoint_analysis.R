library(tidyverse)
library(readr)
library(segmented)
library(changepoint)

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

analyzeBreakpoint <- function(data, lang, prot1, prot2) {
  cat(sprintf("\n=== Breakpoint Analysis: %s - %s vs %s ===\n", lang, prot1, prot2))
  
  data_filtered <- data %>%
    filter(language == lang) %>%
    filter(protocol %in% c(prot1, prot2))
  
  data_filtered <- remover_outliers(data_filtered, "value")
  
  data_summary <- data_filtered %>%
    group_by(payload_size, protocol, experiment_id) %>%
    summarise(
      mean_latency = mean(value, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    group_by(payload_size, protocol) %>%
    summarise(
      mean_latency = mean(mean_latency, na.rm = TRUE),
      se_latency = sd(mean_latency, na.rm = TRUE) / sqrt(n()),
      .groups = "drop"
    )
  
  prot1_data <- data_summary %>%
    filter(protocol == prot1) %>%
    arrange(payload_size)
  
  prot2_data <- data_summary %>%
    filter(protocol == prot2) %>%
    arrange(payload_size)
  
  data_diff <- prot1_data %>%
    inner_join(prot2_data, by = "payload_size", suffix = c(paste0("_", prot1), paste0("_", prot2))) %>%
    mutate(
      diff = get(paste0("mean_latency_", prot1)) - get(paste0("mean_latency_", prot2)),
      se_diff = sqrt(get(paste0("se_latency_", prot1))^2 + get(paste0("se_latency_", prot2))^2)
    ) %>%
    select(payload_size, diff, se_diff)
  
  if (nrow(data_diff) < 5) {
    cat("Insufficient data points for breakpoint analysis\n")
    return(NULL)
  }
  
  cat("\n--- Segmented Regression Analysis ---\n")
  
  model_linear <- lm(diff ~ payload_size, data = data_diff)
  
  initial_breakpoint <- median(data_diff$payload_size)
  
  tryCatch({
    seg_model <- segmented(model_linear, seg.Z = ~payload_size, 
                          psi = list(payload_size = initial_breakpoint))
    
    breakpoint_est <- seg_model$psi[1, 2]
    breakpoint_se <- seg_model$psi[1, 3]
    breakpoint_ci <- confint(seg_model)
    
    cat(sprintf("Breakpoint estimate: %.0f integers\n", breakpoint_est))
    cat(sprintf("Standard error: %.2f\n", breakpoint_se))
    cat(sprintf("95%% Confidence Interval: [%.0f, %.0f]\n", 
                breakpoint_ci[1, 2], breakpoint_ci[1, 3]))
    
    summary_seg <- summary(seg_model)
    cat("\nModel summary:\n")
    print(summary_seg)
    
    slopes <- slope(seg_model)
    cat("\nSlopes:\n")
    print(slopes)
    
    png(sprintf("breakpoint_%s_%s_vs_%s.png", lang, prot1, prot2), 
        width = 1200, height = 800, res = 150)
    par(mfrow = c(1, 2))
    
    plot(data_diff$payload_size, data_diff$diff,
         xlab = "Payload Size (number of integers)",
         ylab = sprintf("Latency Difference (%s - %s)", prot1, prot2),
         main = sprintf("Breakpoint Analysis: %s", lang),
         pch = 19, col = "blue")
    abline(h = 0, col = "gray", lty = 2)
    abline(v = breakpoint_est, col = "red", lty = 2, lwd = 2)
    plot(seg_model, add = TRUE, col = "red", lwd = 2)
    legend("topright", 
           legend = c("Data", "Breakpoint", "Segmented fit"),
           col = c("blue", "red", "red"),
           pch = c(19, NA, NA),
           lty = c(NA, 2, 1),
           lwd = c(NA, 2, 2))
    
    plot(data_summary$payload_size, data_summary$mean_latency,
         col = ifelse(data_summary$protocol == prot1, "blue", "red"),
         pch = 19,
         xlab = "Payload Size (number of integers)",
         ylab = "Mean Latency (seconds)",
         main = sprintf("Performance Comparison: %s", lang))
    legend("topleft",
           legend = c(prot1, prot2),
           col = c("blue", "red"),
           pch = 19)
    
    dev.off()
    
    cat(sprintf("\nPlot saved: breakpoint_%s_%s_vs_%s.png\n", lang, prot1, prot2))
    
  }, error = function(e) {
    cat("Error in segmented regression:", e$message, "\n")
    cat("Falling back to linear model\n")
    print(summary(model_linear))
  })
  
  cat("\n--- Change Point Detection ---\n")
  
  tryCatch({
    data_diff_sorted <- data_diff %>%
      arrange(payload_size)
    
    cpt_result <- cpt.meanvar(data_diff_sorted$diff, method = "PELT", penalty = "BIC")
    
    if (length(cpts(cpt_result)) > 0) {
      change_points <- cpts(cpt_result)
      change_point_sizes <- data_diff_sorted$payload_size[change_points]
      
      cat("Change points detected at payload sizes:\n")
      for (cp in change_point_sizes) {
        cat(sprintf("  %.0f integers\n", cp))
      }
      
      png(sprintf("changepoint_%s_%s_vs_%s.png", lang, prot1, prot2),
          width = 1200, height = 600, res = 150)
      plot(cpt_result, main = sprintf("Change Point Detection: %s", lang))
      dev.off()
      
      cat(sprintf("Change point plot saved: changepoint_%s_%s_vs_%s.png\n", 
                  lang, prot1, prot2))
    } else {
      cat("No change points detected\n")
    }
  }, error = function(e) {
    cat("Error in change point detection:", e$message, "\n")
  })
  
  return(list(
    data_diff = data_diff,
    breakpoint_est = if(exists("breakpoint_est")) breakpoint_est else NA,
    breakpoint_ci = if(exists("breakpoint_ci")) breakpoint_ci else NA
  ))
}

results_go <- analyzeBreakpoint(data, "go", "http", "grpc")
results_java <- analyzeBreakpoint(data, "java", "http", "grpc")

cat("\n=== Summary ===\n")
cat("\nGo - Breakpoint where REST becomes better than gRPC:\n")
if (!is.null(results_go) && !is.na(results_go$breakpoint_est)) {
  cat(sprintf("  Estimate: %.0f integers\n", results_go$breakpoint_est))
  if (!is.na(results_go$breakpoint_ci)) {
    cat(sprintf("  95%% CI: [%.0f, %.0f]\n", 
                results_go$breakpoint_ci[1, 2], results_go$breakpoint_ci[1, 3]))
  }
}

cat("\nJava - Breakpoint where REST becomes better than gRPC:\n")
if (!is.null(results_java) && !is.na(results_java$breakpoint_est)) {
  cat(sprintf("  Estimate: %.0f integers\n", results_java$breakpoint_est))
  if (!is.na(results_java$breakpoint_ci)) {
    cat(sprintf("  95%% CI: [%.0f, %.0f]\n", 
                results_java$breakpoint_ci[1, 2], results_java$breakpoint_ci[1, 3]))
  }
}


