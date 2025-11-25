#!/bin/bash
# run_pipeline.sh
# Pipeline for American Samoa Monthly Rainfall Map Production

set -e  # exit immediately if any command fails

echo "=== Step 1: Aggregate monthly rainfall data (last month) ==="
Rscript as_monthly_rf/as_aggregate_monthly_data.R

echo "=== Step 2: Calculate monthly rainfall map (last month) ==="
Rscript as_monthly_rf/as_aggregate_monthly_maps.R

echo "=== Pipeline complete! Outputs written to NRT subfolders ==="

