# Implementation Guide: Breakpoint Detection Research

This document describes all the changes made to implement the breakpoint detection research plan and how to use the new functionality.

## Table of Contents

1. [Overview](#overview)
2. [Code Changes](#code-changes)
3. [Database Considerations](#database-considerations)
4. [Running Experiments](#running-experiments)
5. [Statistical Analysis](#statistical-analysis)
6. [Troubleshooting](#troubleshooting)

## Overview

The implementation extends the existing research infrastructure to support continuous payload sizes instead of just two discrete sizes ("small" and "big"). This enables systematic exploration of the payload size range to identify the exact breakpoint where REST performance surpasses gRPC.

### Key Changes

- **Payload size parameter**: Changed from string ("small"/"big") to integer (number of integers)
- **Batch experiment execution**: Added function to run multiple experiments across different payload sizes
- **Statistical analysis scripts**: Created three R scripts for breakpoint detection and validation

## Code Changes

### 1. `client/requests.go`

#### Modified Functions

**`getPayload(isHTTP bool, numberOfNumbers int)`**
- **Before**: Accepted `sizeType int` (1 for small, 2 for big)
- **After**: Accepts `numberOfNumbers int` directly
- **Impact**: Allows any payload size to be specified

**`sendJavaHttpRequests`, `sendGoHttpRequests`, `sendJavaGrpcRequests`, `sendGoGrpcRequests`**
- **Before**: Accepted `sizeType int`
- **After**: Accept `numberOfNumbers int`
- **Impact**: All request functions now accept continuous payload sizes

**`runRequests(namespace string, payloadSize int)`**
- **Before**: Accepted `size string` ("small" or "big")
- **After**: Accepts `payloadSize int` (number of integers)
- **Impact**: Main request execution function now uses integer payload sizes

#### Example Usage

```go
// Old way (no longer works)
runRequests("monitoring", "small")  // ❌

// New way
runRequests("monitoring", 200)       // ✅ 200 integers
runRequests("monitoring", 50000)     // ✅ 50,000 integers
runRequests("monitoring", 204800)     // ✅ 204,800 integers
```

### 2. `client/lab.go`

#### Modified Functions

**`runExperiment(experimentId int, payloadSize int)`**
- **Before**: Accepted `size string`
- **After**: Accepts `payloadSize int`
- **Impact**: Experiment function now uses integer payload sizes

**New Function: `runExperimentBatch(experimentIdStart int, payloadSizes []int, runsPerSize int)`**
- **Purpose**: Run multiple experiments across different payload sizes
- **Parameters**:
  - `experimentIdStart`: Starting experiment ID
  - `payloadSizes`: Slice of payload sizes to test
  - `runsPerSize`: Number of experimental runs per payload size
- **Example**:
```go
payloadSizes := []int{200, 500, 1000, 2000, 5000}
runExperimentBatch(1, payloadSizes, 5)  // 5 runs for each of 5 sizes = 25 experiments
```

#### Modified `main()` Function

The main function now runs Phase 1 experiments by default:
```go
payloadSizesPhase1 := []int{200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000, 150000, 204800}
runExperimentBatch(1, payloadSizesPhase1, 5)
```

**To customize experiments**, modify the `main()` function:

```go
func main() {
    // Phase 1: Coarse-grained exploration
    payloadSizesPhase1 := []int{200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000, 150000, 204800}
    runExperimentBatch(1, payloadSizesPhase1, 5)
    
    // Phase 2: Fine-grained refinement (after identifying breakpoint region)
    // Example: if breakpoint is between 50,000 and 100,000
    payloadSizesPhase2 := []int{50000, 60000, 70000, 80000, 90000, 100000}
    runExperimentBatch(56, payloadSizesPhase2, 5)  // Start from experiment ID 56
    
    // Phase 3: Validation (around identified breakpoint)
    // Example: if breakpoint is around 75,000
    payloadSizesPhase3 := []int{70000, 72000, 75000, 78000, 80000}
    runExperimentBatch(86, payloadSizesPhase3, 10)  // 10 runs for validation
}
```

### 3. `client/db.go`

#### Modified Function

**`createTableIfNotExists(db *sql.DB)`**
- **Added**: Database indexes for better query performance
- **Indexes added**:
  - `idx_experiment_id`: For filtering by experiment
  - `idx_app_name`: For filtering by application
  - `idx_request_size`: For filtering by payload size
- **Impact**: Faster queries when analyzing data

**Note**: The `request_size` column remains VARCHAR(255) for backward compatibility. It now stores numeric strings (e.g., "200", "50000") instead of "small"/"big".

## Database Considerations

### Schema Compatibility

The database schema remains compatible with existing data:
- `request_size` column is still VARCHAR(255)
- Old data with "small"/"big" can coexist with new numeric data
- When querying, you may need to handle both formats:

```sql
-- Query numeric sizes
SELECT * FROM experiments WHERE request_size IN ('200', '500', '1000');

-- Query old format (if needed)
SELECT * FROM experiments WHERE request_size IN ('small', 'big');
```

### Data Export for Analysis

To export data for R analysis:

```sql
SELECT 
    id,
    c,
    value,
    experiment_id,
    app_name,
    request_size
FROM experiments
WHERE request_size NOT IN ('small', 'big')  -- Exclude old format if needed
ORDER BY experiment_id, app_name, id;
```

Export to CSV:
```bash
mysql -u admin -p123 metrics -e "SELECT * FROM experiments WHERE request_size NOT IN ('small', 'big')" > dados/experimento_all_sizes.csv
```

Or use the existing R scripts that read from CSV files.

## Running Experiments

### Prerequisites

1. **Kubernetes cluster** must be running with services deployed
2. **Database** must be accessible (MySQL on localhost:3306)
3. **Applications** must be built:
   - Go applications: `go build` in respective directories
   - Java applications: `mvn package` in respective directories

### Step-by-Step Execution

#### 1. Build the Client

```bash
cd client
go build -o lab-client
```

#### 2. Configure Experiment Parameters

Edit `client/lab.go` to set your desired payload sizes:

```go
func main() {
    // Phase 1: Coarse exploration
    payloadSizesPhase1 := []int{200, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100000, 150000, 204800}
    runExperimentBatch(1, payloadSizesPhase1, 5)
}
```

#### 3. Run Experiments

```bash
./lab-client
```

The program will:
- Run experiments for each payload size
- Execute multiple runs per size (as specified)
- Save all metrics to the database
- Print progress information

#### 4. Monitor Progress

Watch the console output for:
- Experiment start/end messages
- Request progress
- Database insertion confirmations
- Any errors

#### 5. Verify Data Collection

Check the database:

```sql
SELECT 
    request_size,
    app_name,
    COUNT(*) as num_measurements,
    AVG(value) as avg_latency
FROM experiments
WHERE request_size NOT IN ('small', 'big')
GROUP BY request_size, app_name
ORDER BY CAST(request_size AS UNSIGNED), app_name;
```

### Running Specific Experiments

To run a single experiment with a specific payload size:

```go
func main() {
    runExperiment(1, 50000)  // Single experiment with 50,000 integers
}
```

## Statistical Analysis

### Prerequisites

Install required R packages:

```r
install.packages(c("tidyverse", "readr", "segmented", "changepoint", "lme4", "boot"))
```

### Data Preparation

1. **Export data from database** (see Database Considerations section)
2. **Save as CSV** in `dados/experimento_all_sizes.csv`
3. **Format**: Should have columns: `id`, `c`, `value`, `experiment_id`, `app_name`, `request_size`

### Running Analysis Scripts

#### 1. Breakpoint Analysis (`breakpoint_analysis.R`)

**Purpose**: Identify breakpoints using segmented regression and change point detection

**Usage**:
```bash
Rscript breakpoint_analysis.R
```

**Output**:
- Console output with breakpoint estimates and confidence intervals
- PNG plots: `breakpoint_go_http_vs_grpc.png`, `breakpoint_java_http_vs_grpc.png`
- PNG plots: `changepoint_go_http_vs_grpc.png`, `changepoint_java_http_vs_grpc.png`

**What it does**:
- Calculates latency differences between REST and gRPC for each payload size
- Fits segmented regression models to find breakpoints
- Performs change point detection
- Generates visualizations

#### 2. Crossover Analysis (`crossover_analysis.R`)

**Purpose**: Model the crossover point using interaction models

**Usage**:
```bash
Rscript crossover_analysis.R
```

**Output**:
- Console output with crossover point estimates
- PNG plots: `crossover_go.png`, `crossover_java.png`

**What it does**:
- Fits linear and quadratic models with protocol × payload_size interaction
- Calculates where REST and gRPC performance lines cross
- Provides confidence intervals for crossover points
- Visualizes performance curves and differences

#### 3. Breakpoint Validation (`breakpoint_validation.R`)

**Purpose**: Validate breakpoint estimates using bootstrap and sensitivity analysis

**Usage**:
```bash
Rscript breakpoint_validation.R
```

**Output**:
- Console output with bootstrap statistics
- PNG plots: `bootstrap_validation_go.png`, `bootstrap_validation_java.png`
- PNG plots: `sensitivity_analysis_go.png`, `sensitivity_analysis_java.png`

**What it does**:
- Performs bootstrap resampling to estimate breakpoint distribution
- Tests sensitivity to outlier removal thresholds
- Provides robust confidence intervals
- Validates breakpoint stability

### Complete Analysis Workflow

```bash
# 1. Run experiments (if not already done)
cd client
go run .

# 2. Export data from database
mysql -u admin -p123 metrics -e "SELECT * FROM experiments WHERE request_size NOT IN ('small', 'big')" > ../dados/experimento_all_sizes.csv

# 3. Run all analysis scripts
cd ..
Rscript breakpoint_analysis.R
Rscript crossover_analysis.R
Rscript breakpoint_validation.R
```

### Interpreting Results

#### Breakpoint Estimates

The scripts will output breakpoint estimates like:
```
Go - Breakpoint where REST becomes better than gRPC:
  Estimate: 45000 integers
  95% CI: [42000, 48000]
```

This means:
- **Point estimate**: REST performance surpasses gRPC at approximately 45,000 integers
- **Confidence interval**: We're 95% confident the true breakpoint is between 42,000 and 48,000 integers

#### Comparing Methods

- **Segmented regression**: Best for identifying single breakpoints with clear slope changes
- **Change point detection**: Useful for detecting multiple change points or variance changes
- **Crossover analysis**: Explicitly models where performance lines cross
- **Bootstrap validation**: Provides robust uncertainty quantification

If all methods converge on similar breakpoints, this increases confidence in the findings.

## Troubleshooting

### Common Issues

#### 1. "Cannot connect to database"

**Error**: `Error ao criar configuração do cliente: ...`

**Solution**:
- Verify MySQL is running: `systemctl status mysql` (Linux) or check MySQL service
- Check connection parameters in `client/db.go`:
  - Host: `localhost:3306`
  - User: `admin`
  - Password: `123`
  - Database: `metrics`

#### 2. "Cannot get LoadBalancer IP"

**Error**: `Erro ao obter o IP do LoadBalancer: ...`

**Solution**:
- Ensure Kubernetes services are deployed
- Check namespace: should be "monitoring"
- Verify services exist:
  ```bash
  kubectl get svc -n monitoring
  ```
- Wait for LoadBalancer IP assignment (may take time)

#### 3. "Application not found"

**Error**: `Erro ao criar aplicação Java/Go: ...`

**Solution**:
- **Java**: Build with `mvn package` in `java-http/` and `java-grpc/`
- **Go**: Build with `go build` in `go-http/api/` and `go-grpc/api/`
- Verify paths in `client/requests.go` are correct

#### 4. "Insufficient data for analysis"

**Error in R scripts**: "Insufficient data points for breakpoint analysis"

**Solution**:
- Ensure you have data for at least 5 different payload sizes
- Check that data was exported correctly
- Verify CSV file format matches expected structure

#### 5. "Segmented regression failed"

**Error in R**: "Error in segmented regression"

**Solution**:
- Try different initial breakpoint estimates
- Check data quality (outliers, missing values)
- Ensure sufficient data points around suspected breakpoint
- Consider using change point detection as alternative

### Performance Considerations

#### Experiment Duration

- **Single experiment**: ~5-10 minutes (depends on number of requests)
- **Phase 1 (11 sizes × 5 runs)**: ~5-10 hours
- **Full workflow (all phases)**: ~15-20 hours

#### Resource Usage

- **Memory**: Ensure sufficient RAM for large payloads (204,800 integers)
- **Network**: Experiments generate significant network traffic
- **Database**: Monitor database size growth

### Best Practices

1. **Start small**: Test with 2-3 payload sizes first
2. **Monitor resources**: Watch CPU, memory, and network usage
3. **Save progress**: Database automatically saves, but consider backups
4. **Validate data**: Check data quality after each phase
5. **Iterate**: Use Phase 1 results to guide Phase 2 payload selection

## Next Steps

After completing the implementation:

1. **Run Phase 1 experiments** to get initial breakpoint estimates
2. **Analyze Phase 1 data** to identify breakpoint regions
3. **Run Phase 2 experiments** with fine-grained payload sizes around breakpoints
4. **Run Phase 3 validation** with increased sample sizes
5. **Compare results** across all three analysis methods
6. **Document findings** in your thesis

## File Structure

```
.
├── client/
│   ├── requests.go      # Modified: continuous payload sizes
│   ├── lab.go          # Modified: batch experiment execution
│   ├── db.go           # Modified: added indexes
│   └── kube.go         # Unchanged
├── breakpoint_analysis.R      # New: segmented regression & change points
├── crossover_analysis.R       # New: interaction models
├── breakpoint_validation.R    # New: bootstrap & sensitivity
├── RESEARCH_PLAN.md          # Research methodology
└── IMPLEMENTATION_GUIDE.md    # This file
```

## Support

For issues or questions:
1. Check this guide first
2. Review the research plan (`RESEARCH_PLAN.md`)
3. Check R package documentation
4. Review existing R scripts for examples

---

**Last Updated**: Implementation complete
**Version**: 1.0


