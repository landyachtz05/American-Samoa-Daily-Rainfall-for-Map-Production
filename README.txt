American Samoa Daily Rainfall Maps Production

Required R Packages:
   Package Version
    raster  3.6-23
        sf  1.0-14
     dplyr   1.1.3
     gstat   2.1-1
   Metrics   0.1.4
     readr   2.1.4
   stringr   1.5.2
      httr   1.4.7
 lubridate   1.9.3
  jsonlite   1.8.7

Inputs:
a. Data acquisition R scripts:
NRT/AS_mesonet_yesterday_acquisition.R - pulls yesterday’s Mesonet precipitation data and sums to daily.
NRT/AS_WRCC_yesterday_acquisition.R - pulls yesterday’s WRCC precipitation daily data.

b. Data processing R scripts
NRT/as_nrt_combine.R - merges Mesonet + WRCC data into one combined dataset.
NRT/day_rf_IDW_derekversion_NRT.R - runs IDW interpolation to create rainfall maps/rasters.

c. Supporting R functions
NRT/as_dataDateFunc.R - functions for calling yesterday's date.
NRT/AS_RF_funcs.R - functions for rainfall interpolation.

d. Static spatial inputs
NRT/as_static_files/as_coastline.shp (+ .shx, .dbf, .prj, etc.) - shapefile of American Samoa coastline.
NRT/as_static_files/as_mask3.tif - raster mask for clipping final output.
NRT/as_static_files/as_prism_monthday/
daily_01_mm.tif
daily_02_mm.tif
...
daily_12_mm.tif - climatological baseline rasters (PRISM daily normals derived from monthly climatology maps).

Outputs:
NRT/as_individual_data/:
as_mesonet_YYYY_MM_DD.csv - summed daily station data from HI Mesonet
as_wrcc_YYYY_MM_DD.csv - raw daily station data from WRCC

NRT/as_combined_data/
YYYYMMDD_as_rf_idw_input.csv - combined Mesonet + WRCC dataset, formatted for IDW

NRT/as_idw_rf_maps_NRT/
as_idw_map_YYYYMMDD.png - PNG visualization of interpolated rainfall map

NRT/as_idw_rf_ras_NRT/
as_idw_ras_YYYYMMDD.tif - GeoTIFF raster of interpolated rainfall (primary product for mapping/analysis)

NRT/as_idw_rf_meta_NRT/
as_idw_meta_YYYYMMDD.txt - metadata/log for the IDW run (interpolation status, parameters, error metrics)

NRT/as_idw_rf_table_NRT/
daily_rainfall_station_AS_YYYY_MM_DD.csv - table of rainfall at each station used in the interpolation
