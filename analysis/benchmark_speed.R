library(tidyverse)
library(skylight)
library(microbenchmark)

df <- readRDS("../the_long_journey_of_CC894/data/geolocator_data_annotated.rds")

results <- microbenchmark(
  skylight(
    longitude = 3.72875,
    latitude = 51.0779,
    date = df$date_time[1:100],
    sky_condition = 1,
    fast = TRUE
  ),
  skylight(
    longitude = 3.72875,
    latitude = 51.0779,
    date = df$date_time[1:100],
    sky_condition = 1,
    fast = FALSE
  ),
  times = 100
)

print(results)
boxplot(results, names=c('fast', 'slow'))


results <- microbenchmark(
  skylight(
    longitude = 3.72875,
    latitude = 51.0779,
    date = df$date_time[1:10000],
    sky_condition = 1,
    fast = TRUE
  ),
  skylight(
    longitude = 3.72875,
    latitude = 51.0779,
    date = df$date_time[1:10000],
    sky_condition = 1,
    fast = FALSE
  ),
  times = 100
)

print(results)
boxplot(results, names=c('fast', 'slow'))
