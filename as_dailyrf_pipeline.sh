#!/bin/bash
# run_pipeline.sh
# Pipeline for American Samoa Daily Rainfall Map Production

set -e  # exit immediately if any command fails

echo "=== Step 1: Pulling Mesonet data (yesterday) ==="
Rscript AS_mesonet_yesterday_acquisition.R

echo "=== Step 2: Pulling WRCC data (yesterday) ==="
Rscript AS_WRCC_yesterday_acquisition.R

echo "=== Step 3: Combining station data ==="
Rscript as_nrt_combine.R

echo "=== Step 4: Gapfilling station data ==="
Rscript as_gapfill.R

echo "=== Step 5: Running IDW interpolation and producing rainfall map ==="
Rscript day_rf_IDW_derekversion_NRT.R

echo "=== Pipeline complete! Outputs written to NRT subfolders ==="

