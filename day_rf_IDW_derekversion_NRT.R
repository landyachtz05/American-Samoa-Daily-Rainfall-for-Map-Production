### Make daily RF maps from climatologically-aided interpolation using IDW and 
### optimized through LOOCV. Requires AS_RF_funcs.R functions code.

library(raster)
library(sf)
library(dplyr)

rm(list = ls())#remove all objects in R

source("F:/PDKE/american_samoa/AS_RF_funcs.R") # calls functions code

#input Data/vars
setwd("F:/PDKE/american_samoa/")

# Create output directories if they don't exist
if (!dir.exists("NRT/as_idw_rf_ras_NRT")) dir.create("NRT/as_idw_rf_ras_NRT")
if (!dir.exists("NRT/as_idw_rf_meta_NRT")) dir.create("NRT/as_idw_rf_meta_NRT")
if (!dir.exists("NRT/as_idw_rf_maps_NRT")) dir.create("NRT/as_idw_rf_maps_NRT")
if (!dir.exists("NRT/as_idw_rf_table_NRT")) dir.create("NRT/as_idw_rf_table_NRT")

# Load static data
ASmask <- raster("as_mask3.tif")
AScoast <- st_read("as_coastline.shp")

# List all CSV files for each day
csv_files <- list.files("NRT/all", pattern = "\\.csv$", full.names = TRUE)

### Work this to start right before loop and end after
s<-Sys.time()

csv_file <- csv_files[1]

# Extract date from file name
date <- as.Date(substr(basename(csv_file), 1, 8), format = "%Y%m%d")
date_ <- as.Date
date_str <- format(date, "%Y%m%d")  # e.g. "19580701"
date_str

# Load PRISM raster for corresponding month
month <- format(date, "%m")
ASmeanRFday <- raster(paste0("PRISM/PRISM_daily/daily_", month, "_mm.tif"))
# meanRFday<-ASmeanRFday

# Load daily station data table template
temp <- read.csv("NRT/daily_rainfall_station_AS_template.csv")

# Load daily rainfall station data
rfSta <- read.csv(csv_file)

# Conditional skips interpolation if there's less than 2 stations available
if (sum(!is.na(rfSta$total_rf_mm)) < 2) {
  warning("Not enough data points to run IDW")
  # return(NULL)  # or return a dummy raster
  best_idw_rf <- NULL  # produce no map 
  # Create metadata explaining fallback
  metadata <- data.frame(
    variable = "interpolation_status",
    value = "Not enough data points to run IDW. No map produced.",
    stringsAsFactors = FALSE
  )
  
} else {
  testOut <- bestIDWrfFun(rfSta = rfSta,
                          mask = ASmask,
                          date = date,
                          meanRFday = ASmeanRFday)

# Extract outputs
best_idw_rf <- testOut[["best_idw_rf"]]
plot(best_idw_rf)
metadata <- testOut[["metadata"]]
metadata$value <- as.character(metadata$value)
}

if (!is.null(best_idw_rf)) {
  # Set raster background value to -9999
  best_idw_rf[is.na(best_idw_rf[])] <- -9999
  
  # Or more explicitly
  best_idw_rf <- reclassify(best_idw_rf, cbind(NA, NA, -9999))
  
  # Save raster
  raster_outfile <- paste0("NRT/as_idw_rf_ras_NRT/as_idw_", date_str, ".tif")
  writeRaster(best_idw_rf, raster_outfile, overwrite = TRUE)

  # Save metadata as a tab-separated text file
  meta_outfile <- paste0("NRT/as_idw_rf_meta_NRT/as_idw_meta_", date_str, ".txt")
  write.table(metadata, meta_outfile, sep = "\t", row.names = FALSE, quote = FALSE)
  
  # Save daily data file for map-viewer display
    # Make a copy so we don’t overwrite original temp right away
    temp_out <- temp
    
    # Column name from date
    col_name <- paste0("X", format(date, "%Y_%m_%d"))
    
    # Join rfSta$total_rf_mm into temp by SKN
    temp_out <- temp_out %>%
      left_join(rfSta %>% select(SKN, total_rf_mm), by = "SKN")
    
    # Replace XDATE with new column name, filled with matched values
    temp_out[[col_name]] <- temp_out$total_rf_mm
    temp_out$total_rf_mm <- NULL  # remove helper column if not needed
    temp_out$XDATE <- NULL        # drop the old XDATE column
    
    table_outfile <- paste0("NRT/as_idw_rf_table_NRT/daily_rainfall_station_AS_",
                            format(date, "%Y_%m_%d"),".csv")
    write.csv(temp_out, table_outfile)
  
  # Prepare plot
  png(filename = paste0("NRT/as_idw_rf_maps_NRT/as_idw_map_", date_str, ".png")
      , width = 600, height = 400
      )
  # par(mar = c(4, 4, 4, 6))  # Give some room for subtext
  par(mar = c(5, 4, 4, 2))  # bottom margin slightly larger for subtext
  
  rfSta_non_na <- rfSta[!is.na(rfSta$total_rf_mm), ]
  subtext <- paste(paste(metadata$var[7:12], metadata$value[7:12], sep=": "), collapse = "; ")
  
  plot(best_idw_rf, col=rainbow(100, end=0.8), 
       main = paste(date, "IDW"),
       zlim = c(0, 200))
  
  # Add subtext under the plot using mtext
  mtext(subtext, side = 1, line = 4, cex = 0.8)  # side = 1 = bottom, line = 4 pushes it down
  
  # Overlay coast and points
  plot(AScoast, col=NA, border="black", add=TRUE)
  points(rfSta_non_na$LON, rfSta_non_na$LAT, col = "black", pch = 16)
  
  # Add station names + rainfall
  labels <- paste(rfSta_non_na$Station.Name, round(rfSta_non_na$total_rf_mm, 2), sep = "\n")
  if(sum(!is.na(rfSta$total_rf_mm)) > 0){
    text(rfSta_non_na$LON, rfSta_non_na$LAT, labels = labels, pos = 4, cex = 0.8)
  }
  
  dev.off()
  
  message("Processed and saved: ", date_str)
}

# finish day map
e<-Sys.time()
write(difftime(e,s,units="hours"),"tt.txt")

