American Samoa Daily Rainfall Maps Outputs

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