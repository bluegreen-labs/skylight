library(tidyverse)
library(skylight)
library(microbenchmark)
source("R/skylight.R")

df <- readRDS("../the_long_journey_of_CC894/data/geolocator_data_annotated.rds")

fast <- skylight(
  longitude = 3.72875,
  latitude = 51.0779,
  date = df$date_time[1:100],
  sky_condition = 1,
  fast = TRUE
)

slow <- skylight(
  longitude = 3.72875,
  latitude = 51.0779,
  date = df$date_time[1:100],
  sky_condition = 1,
  fast = FALSE
)

plot(fast$total_illuminance, slow$total_illuminance)
abline(0,1)
