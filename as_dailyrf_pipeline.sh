#!/bin/bash
# run_pipeline.sh
# Pipeline for American Samoa Daily Rainfall Map Production

set -e  # exit immediately if any command fails

: "${PROJECT_ROOT:?PROJECT_ROOT is not set. Export PROJECT_ROOT before running.}"

DATE="$1"
if [ -z "$DATE" ]; then
  echo "Usage: $0 YYYY-MM-DD"
  exit 1
fi

if ! [[ "$DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "ERROR: DATE must be ISO 8601 format YYYY-MM-DD (got: $DATE)"
  exit 1
fi

DATESTR="${DATE//-/}"

echo "=== Step 1: Pulling Mesonet data ($DATE) ==="
Rscript AS_mesonet_yesterday_acquisition.R "$DATE"

echo "=== Step 2: Pulling WRCC data ($DATE) ==="
Rscript AS_WRCC_yesterday_acquisition.R "$DATE"

echo "=== Step 3: Combining station data ($DATE) ==="
Rscript as_nrt_combine.R "$DATE"

echo "=== Step 4: Gapfilling station data ($DATE) ==="
Rscript as_gapfill.R "$DATE"

echo "=== Step 5: Running IDW interpolation and producing rainfall map ($DATE) ==="
Rscript day_rf_IDW_derekversion_NRT.R "$DATE"

echo "=== Step 6: Fix GeoTIFF header nodata (GDAL_NODATA = -9999) ==="
TIF="${PROJECT_ROOT}/as_idw_rf_ras_NRT/as_idw_${DATESTR}.tif"

if [ ! -f "$TIF" ]; then
  echo "ERROR: Expected GeoTIFF not found: $TIF"
  exit 1
fi

python3 - <<PY
import rasterio
tif = r"""$TIF"""
with rasterio.open(tif, "r+") as src:
    src.nodata = -9999
with rasterio.open(tif) as src:
    print("nodata now =", src.nodata)
PY

echo "=== Pipeline complete! Outputs written to NRT subfolders ==="

