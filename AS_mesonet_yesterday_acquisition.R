###### American Samoa Rainfall Data Acquisition - UH Mesonet

library(httr)
library(jsonlite)
library(tidyr)
library(dplyr)
library(tibble)
library(purrr)

### Find all AS stations
# Define the API URL
url <- "https://api.hcdp.ikewai.org/mesonet/getStations"

# Set the request parameters for American Samoa
params <- list(
  location = "american_samoa"
)

# Set up the authorization token
auth_token <- "Bearer c3c6c404f9aad7c5831b9b5e5319653a"

resp <- GET(
  "https://api.hcdp.ikewai.org/mesonet/db/stations",
  add_headers(Authorization = auth_token),
  query = list(location = "american_samoa")
)

if (status_code(resp) == 200) {
  stations <- fromJSON(content(resp, as = "text", encoding = "UTF-8"))
  print(stations)
} else {
  stop("Error: ", status_code(resp), " - ", content(resp, as = "text"))
}

################################################################################
################################################################################
# Use Poloa, Aasu, Vaipito, Afono, Aunuu

library(httr)
library(jsonlite)
library(dplyr)
library(lubridate)

# ---- Settings ----
auth_token <- "Bearer c3c6c404f9aad7c5831b9b5e5319653a"
station_ids <- c("1311", "1312", "1313", "1316", "1319")
var_id <- "RF_1_Tot300s"
tz_local <- "Pacific/Pago_Pago"
target_date <- Sys.Date() - 1

expected <- 288
threshold <- ceiling(expected * 0.95)

output_folder <- "F:/PDKE/american_samoa/rain_data/NRT"
if (!dir.exists(output_folder)) dir.create(output_folder)

# ---- Pull station metadata dynamically ----
resp_meta <- GET(
  "https://api.hcdp.ikewai.org/mesonet/db/stations",
  add_headers(Authorization = auth_token),
  query = list(location = "american_samoa")
)

if (status_code(resp_meta) == 200) {
  stations <- fromJSON(content(resp_meta, as = "text", encoding = "UTF-8"))
  # Filter only the stations of interest
  station_meta <- stations %>%
    filter(as.character(station_id) %in% station_ids) %>%
    mutate(
      station_id = as.character(station_id),
      SKN = case_when(
        station_id == "1311" ~ 1021,
        station_id == "1312" ~ 1001,
        station_id == "1313" ~ 1026,
        station_id == "1316" ~ 1004,
        station_id == "1319" ~ 1010
      ),
      Station.Name = case_when(
        station_id == "1311" ~ "poloa_UH",
        station_id == "1312" ~ "aasu_UH",
        station_id == "1313" ~ "vaipito_UH",
        station_id == "1316" ~ "afono_UH",
        station_id == "1319" ~ "aunuu_UH"
      ),
      Elev.m = elevation,
      LAT   = lat,
      LON   = lng
    ) %>%
    select(station_id, SKN, Station.Name, Elev.m, LAT, LON)
  
} else {
  stop("Failed to pull station metadata: ", status_code(resp_meta))
}

# ---- Pull daily data for each station ----
all_daily_summary <- list()

for (station in station_ids) {
  start_utc <- with_tz(as.POSIXct(target_date, tz = tz_local), tzone = "UTC")
  end_utc   <- with_tz(as.POSIXct(target_date + 1, tz = tz_local) - 300, tzone = "UTC")
  
  resp <- GET(
    "https://api.hcdp.ikewai.org/mesonet/db/measurements",
    add_headers(Authorization = auth_token),
    query = list(
      station_ids = station,
      var_ids     = var_id,
      start_date  = format(start_utc, "%Y-%m-%dT%H:%M:%S"),
      end_date    = format(end_utc, "%Y-%m-%dT%H:%M:%S"),
      local_tz    = "True",
      location    = "american_samoa",
      row_mode    = "json"
    )
  )
  
  if (status_code(resp) == 200) {
    data_raw <- fromJSON(content(resp, as = "text", encoding = "UTF-8"))
    if (length(data_raw) > 0 && "timestamp" %in% names(data_raw)) {
      data_tbl <- as_tibble(data_raw) %>%
        mutate(
          timestamp = ymd_hms(timestamp, tz = tz_local),
          value = as.numeric(value),
          date = as.Date(timestamp)
        ) %>%
        distinct(timestamp, .keep_all = TRUE) %>%
        mutate(station_id = station)
      
      daily_summary <- data_tbl %>%
        group_by(station_id, date) %>%
        summarise(
          n_subdaily = n(),
          daily_total = sum(value, na.rm = TRUE),
          .groups = "drop"
        ) %>%
        mutate(
          value = ifelse(n_subdaily >= threshold, daily_total, NA),
          variable = "precip_mm",
          completeness = n_subdaily / expected
        ) %>%
        select(station_id, date, value, variable, completeness)
      
      all_daily_summary[[station]] <- daily_summary
    } else {
      warning("No data for station ", station)
    }
  } else {
    warning("Failed for station ", station, ": ", status_code(resp))
  }
}

# ---- Combine all stations and join metadata ----
all_daily_summary <- bind_rows(all_daily_summary) %>%
  left_join(station_meta, by = "station_id") %>%
  mutate(Observer = "UH") %>%
  select(station_id, SKN, Station.Name, Observer, Elev.m, LAT, LON, date, value, variable, completeness) %>%
  arrange(station_id, date)

all_daily_summary

# ---- Write CSV ----
output_file <- file.path(output_folder, paste0("as_mesonet_", gsub("-", "_", target_date), ".csv"))
write.csv(all_daily_summary, output_file, row.names = FALSE)
message("Daily summary with metadata saved to: ", output_file)

