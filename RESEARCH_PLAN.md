# Research Plan: Determining the Payload Size Breakpoint Where REST Outperforms gRPC

## Executive Summary

This research plan aims to extend the current findings that gRPC outperforms REST for standard-sized requests, while REST becomes more efficient for larger payloads. The primary objective is to identify the exact payload size threshold (breakpoint) where the performance crossover occurs using rigorous statistical methods.

## Current Research Status

### Existing Findings
- **Small requests (200 numbers)**: gRPC demonstrates superior performance
- **Large requests (204,800 numbers)**: REST demonstrates superior performance
- **Methodology**: 2^k factorial design, ANOVA, Wilcoxon tests, Kruskal-Wallis tests
- **Applications tested**: Java HTTP, Java gRPC, Go HTTP, Go gRPC
- **Metrics**: Response time (latency in seconds)

### Current Limitations
- Only two discrete payload sizes tested (200 vs 204,800)
- No continuous range of payload sizes to identify the breakpoint
- Statistical methods focus on comparison rather than breakpoint detection

## Research Objectives

### Primary Objective
Identify the specific payload size (in number of integers) at which REST's performance metrics statistically surpass gRPC's performance for both Go and Java implementations.

### Secondary Objectives
1. Characterize the performance relationship between payload size and latency for both protocols
2. Determine if breakpoints differ between Go and Java implementations
3. Validate findings through multiple experimental runs
4. Provide confidence intervals for identified breakpoints

## Proposed Methodology

### 1. Experimental Design

#### 1.1 Payload Size Selection Strategy

**Current approach**: Binary comparison (200 vs 204,800)

**Proposed approach**: Systematic sampling across a continuous range

**Recommended payload sizes** (number of integers):
- **Phase 1 - Coarse-grained exploration**: 
  - 200, 500, 1,000, 2,000, 5,000, 10,000, 20,000, 50,000, 100,000, 150,000, 204,800
- **Phase 2 - Fine-grained refinement** (around identified breakpoint):
  - If breakpoint found between X and Y, test: X, X+0.2(Y-X), X+0.4(Y-X), X+0.6(Y-X), X+0.8(Y-X), Y
- **Phase 3 - Validation**:
  - Test 3-5 sizes around the identified breakpoint with increased sample sizes

**Rationale**: 
- Logarithmic spacing in Phase 1 allows efficient exploration of the full range
- Fine-grained Phase 2 provides precise breakpoint identification
- Phase 3 validates findings with higher statistical power

#### 1.2 Sample Size Determination

**Current approach**: 
- Go: 248 requests per experiment
- Java: 1,248 requests per experiment

**Proposed approach**: 
- Use power analysis based on effect sizes from current data
- Minimum 30-50 independent measurements per payload size (following central limit theorem)
- Multiple experimental runs (5-10) per payload size to account for variability
- Consider using the sample size calculation from `sampleSizes.R` and `repetitionSizes.R`

**Statistical power**: Aim for 80-90% power with α = 0.05

#### 1.3 Experimental Controls

Maintain consistency with current methodology:
- Same Kubernetes environment
- Same network conditions
- Same hardware configuration
- Same timing intervals (1 second between requests)
- Same outlier removal method (3.5 × IQR)

### 2. Statistical Analysis Methods

#### 2.1 Breakpoint Detection Methods

**Method 1: Segmented (Piecewise) Regression**

**Purpose**: Model the relationship between payload size and latency with an unknown breakpoint

**Implementation in R**:
```r
library(segmented)

# For each protocol (gRPC vs REST) and language (Go vs Java)
model <- lm(latency ~ payload_size, data = data)
segmented_model <- segmented(model, seg.Z = ~payload_size, 
                             psi = list(payload_size = c(50000, 100000)))
summary(segmented_model)
```

**Advantages**:
- Estimates breakpoint location and confidence intervals
- Provides separate slopes before and after breakpoint
- Well-established statistical method

**Method 2: Change Point Detection**

**Purpose**: Identify points where the relationship between payload size and latency changes

**Implementation in R**:
```r
library(changepoint)

# For difference between REST and gRPC
diff_data <- rest_latency - grpc_latency
cpt_result <- cpt.meanvar(diff_data, method = "PELT")
plot(cpt_result)
```

**Advantages**:
- Detects multiple change points if they exist
- Handles variance changes
- Non-parametric options available

**Method 3: Interaction Model with Continuous Breakpoint**

**Purpose**: Model the crossover point explicitly

**Implementation**:
```r
# Create interaction term
data$protocol <- as.factor(data$protocol)
data$size_centered <- data$payload_size - mean(data$payload_size)

# Model with interaction
model <- lm(latency ~ protocol * size_centered + protocol * I(size_centered^2), 
            data = data)

# Find where lines cross
# Solve: intercept_rest + slope_rest * x = intercept_grpc + slope_grpc * x
```

**Advantages**:
- Explicitly models the crossover
- Can test for significance of breakpoint
- Allows for non-linear relationships

#### 2.2 Comparison Methods (Current + Enhanced)

**Enhanced ANOVA with Payload Size as Continuous Variable**:
```r
# Mixed-effects model accounting for payload size
library(lme4)
model <- lmer(latency ~ protocol * payload_size + (1|experiment_id), 
              data = data)
```

**Pairwise Comparisons at Each Payload Size**:
- Wilcoxon rank-sum tests (non-parametric)
- Effect size calculations (Cohen's d)
- Multiple comparison correction (Bonferroni or FDR)

#### 2.3 Visualization Methods

**Recommended plots**:
1. **Scatter plot with regression lines**: Payload size vs latency, colored by protocol
2. **Difference plot**: REST latency - gRPC latency vs payload size (breakpoint where line crosses zero)
3. **Confidence bands**: Show uncertainty around breakpoint estimates
4. **Interaction plots**: Show how protocol effect changes with payload size

### 3. Implementation Plan

#### Phase 1: Code Modifications

**File: `client/requests.go`**

**Current implementation**:
```go
func getPayload(isHTTP bool, sizeType int) interface{} {
    numberOfNumbers := 204800
    switch sizeType {
        case 1:
            numberOfNumbers = 200
        case 2:
            numberOfNumbers = 204800
        // ...
    }
}
```

**Proposed modification**:
```go
func getPayload(isHTTP bool, numberOfNumbers int) interface{} {
    // numberOfNumbers passed as parameter instead of sizeType
    goArray := make([]int32, numberOfNumbers)
    // ... rest of implementation
}
```

**File: `client/lab.go`**

**Proposed modification**:
```go
func runExperiment(experimentId int, payloadSize int) {
    // payloadSize is now an integer specifying exact number of integers
    metrics := runRequests(namespace, payloadSize)
    persistMetrics(experimentId, payloadSize, metrics)
}
```

**Database schema update**:
- Change `request_size` from VARCHAR to INTEGER
- Store actual number of integers instead of "small"/"big"

#### Phase 2: Data Collection

**Timeline**: 
- Phase 1 (coarse): 12 payload sizes × 4 applications × 5 runs = 240 experiments
- Phase 2 (fine): 6 payload sizes × 4 applications × 5 runs = 120 experiments  
- Phase 3 (validation): 5 payload sizes × 4 applications × 10 runs = 200 experiments

**Total**: ~560 experimental runs

**Automation**: 
- Modify `lab.go` to iterate through payload sizes
- Implement automated scheduling to run experiments sequentially
- Add data validation checks after each experiment

#### Phase 3: Statistical Analysis

**New R scripts to create**:

1. **`breakpoint_analysis.R`**:
   - Segmented regression analysis
   - Change point detection
   - Breakpoint estimation with confidence intervals

2. **`crossover_analysis.R`**:
   - Interaction model analysis
   - Crossover point calculation
   - Visualization of crossover

3. **`breakpoint_validation.R`**:
   - Bootstrap confidence intervals for breakpoints
   - Sensitivity analysis
   - Robustness checks

### 4. Expected Statistical Results

#### 4.1 Breakpoint Estimates

For each combination (Go gRPC vs Go REST, Java gRPC vs Java REST):
- Point estimate of breakpoint (e.g., "REST becomes better at 45,000 integers")
- 95% confidence interval (e.g., "42,000 - 48,000 integers")
- Statistical significance of breakpoint

#### 4.2 Performance Characterization

- Slope of latency vs payload size before breakpoint
- Slope of latency vs payload size after breakpoint
- Rate of change in performance difference
- Effect sizes at various payload sizes

#### 4.3 Language-Specific Findings

- Comparison of breakpoints between Go and Java
- Assessment of whether breakpoints are language-dependent
- Protocol-specific patterns (gRPC vs REST) across languages

### 5. Validation and Robustness

#### 5.1 Internal Validation

- **Bootstrap resampling**: Estimate breakpoint distribution
- **Cross-validation**: Split data into training/validation sets
- **Sensitivity analysis**: Test robustness to outlier removal thresholds
- **Model diagnostics**: Check assumptions of regression models

#### 5.2 External Validation

- **Replication**: Run experiments on different days/times
- **Different network conditions**: Test under varying load
- **Multiple experimental runs**: Ensure consistency across runs

### 6. Literature Review Recommendations

#### 6.1 Key Papers to Review

1. **Segmented Regression**:
   - Muggeo, V. M. (2003). "Estimating regression models with unknown break-points". Statistics in Medicine, 22(19), 3055-3071.

2. **Change Point Detection**:
   - Killick, R., & Eckley, I. (2014). "changepoint: An R package for changepoint analysis". Journal of Statistical Software, 58(3), 1-19.

3. **Performance Benchmarking**:
   - Existing gRPC vs REST comparison studies
   - Network protocol performance analysis papers

4. **Statistical Methods for Breakpoints**:
   - Papers on piecewise regression
   - Threshold regression models
   - Structural break detection

#### 6.2 Relevant Statistical Packages

- **R packages**: `segmented`, `changepoint`, `strucchange`, `mcp` (multiple change points)
- **Python alternatives**: `ruptures`, `scipy.optimize` for custom breakpoint detection

### 7. Timeline and Milestones

#### Week 1-2: Preparation
- [ ] Literature review on breakpoint detection methods
- [ ] Code modifications to support continuous payload sizes
- [ ] Database schema updates
- [ ] Pilot test with 3-5 payload sizes

#### Week 3-5: Phase 1 Data Collection
- [ ] Run coarse-grained experiments (12 payload sizes)
- [ ] Initial data quality checks
- [ ] Preliminary breakpoint estimates

#### Week 6-7: Phase 2 Data Collection
- [ ] Identify candidate breakpoint regions
- [ ] Run fine-grained experiments (6 payload sizes)
- [ ] Refine breakpoint estimates

#### Week 8-9: Phase 3 Validation
- [ ] Run validation experiments (5 payload sizes, increased sample size)
- [ ] Final breakpoint estimation
- [ ] Confidence interval calculation

#### Week 10-11: Analysis and Documentation
- [ ] Complete statistical analysis
- [ ] Create visualizations
- [ ] Write results section
- [ ] Prepare presentation materials

#### Week 12: Review and Refinement
- [ ] Peer review of methodology and results
- [ ] Address feedback
- [ ] Final documentation

### 8. Success Criteria

#### Quantitative Criteria
1. **Breakpoint identification**: Identify breakpoint with 95% confidence interval width < 10% of breakpoint value
2. **Statistical significance**: Breakpoint is statistically significant (p < 0.05)
3. **Reproducibility**: Breakpoint estimates consistent across multiple experimental runs
4. **Effect size**: Clear performance difference (> 10%) on either side of breakpoint

#### Qualitative Criteria
1. **Methodological rigor**: Use of established statistical methods
2. **Comprehensive analysis**: Multiple methods converge on similar breakpoint
3. **Clear documentation**: Methodology and results clearly explained
4. **Practical relevance**: Findings applicable to real-world scenarios

### 9. Potential Challenges and Mitigation

#### Challenge 1: Wide Confidence Intervals
**Mitigation**: 
- Increase sample size
- Use more efficient experimental design
- Consider Bayesian methods for better uncertainty quantification

#### Challenge 2: Multiple Breakpoints
**Mitigation**:
- Use methods that detect multiple change points
- Test for non-linear relationships
- Consider spline regression

#### Challenge 3: Language-Specific Differences
**Mitigation**:
- Analyze Go and Java separately
- Report language-specific breakpoints
- Investigate implementation differences

#### Challenge 4: High Variability
**Mitigation**:
- Increase number of experimental runs
- Use mixed-effects models to account for experiment-level variability
- Implement more robust outlier detection

### 10. Deliverables

1. **Code modifications**: Updated Go code for continuous payload sizes
2. **R analysis scripts**: Breakpoint detection and analysis scripts
3. **Dataset**: Complete experimental data with all payload sizes
4. **Statistical report**: Detailed analysis with breakpoint estimates
5. **Visualizations**: Plots showing breakpoints and performance relationships
6. **Updated thesis section**: Methodology and results sections incorporating breakpoint analysis

### 11. References and Resources

#### Statistical Methods
- Segmented regression: Muggeo (2003)
- Change point detection: Killick & Eckley (2014)
- Piecewise regression: Toms & Lesperance (2003)

#### R Packages Documentation
- `segmented`: https://cran.r-project.org/package=segmented
- `changepoint`: https://cran.r-project.org/package=changepoint
- `strucchange`: https://cran.r-project.org/package=strucchange

#### Performance Benchmarking
- gRPC vs REST comparison studies
- Network protocol performance analysis

### 12. Next Steps

1. **Immediate actions**:
   - Review and approve this research plan
   - Begin literature review on breakpoint detection methods
   - Start code modifications for continuous payload sizes

2. **Short-term** (next 2 weeks):
   - Complete code modifications
   - Run pilot experiments
   - Validate data collection pipeline

3. **Medium-term** (next 2 months):
   - Complete Phase 1 and Phase 2 data collection
   - Begin statistical analysis
   - Refine methodology based on initial findings

---

## Appendix: Example R Code Skeleton

### Breakpoint Detection Example

```r
library(segmented)
library(tidyverse)

# Load data
data <- read_csv("dados/experimento_all_sizes.csv")

# Prepare data: calculate difference between REST and gRPC
data_diff <- data %>%
  filter(language == "go") %>%
  group_by(payload_size, experiment_id) %>%
  summarise(
    rest_latency = mean(value[protocol == "http"], na.rm = TRUE),
    grpc_latency = mean(value[protocol == "grpc"], na.rm = TRUE),
    diff = rest_latency - grpc_latency
  ) %>%
  group_by(payload_size) %>%
  summarise(
    mean_diff = mean(diff, na.rm = TRUE),
    se_diff = sd(diff, na.rm = TRUE) / sqrt(n())
  )

# Segmented regression
model <- lm(mean_diff ~ payload_size, data = data_diff)
seg_model <- segmented(model, seg.Z = ~payload_size, 
                       psi = list(payload_size = 50000))

# Extract breakpoint
breakpoint <- seg_model$psi[1, 2]
breakpoint_ci <- confint(seg_model)

# Plot
plot(data_diff$payload_size, data_diff$mean_diff,
     xlab = "Payload Size (number of integers)",
     ylab = "REST Latency - gRPC Latency (seconds)")
abline(v = breakpoint, col = "red", lty = 2)
plot(seg_model, add = TRUE, col = "blue")
```

---

**Document Version**: 1.0  
**Last Updated**: [Current Date]  
**Author**: Research Plan based on current methodology review


