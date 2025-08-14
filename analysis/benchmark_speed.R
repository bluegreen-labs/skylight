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
  times = 100000,
  unit = "ms"
)

par(mfrow=c(5,2))

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
  times = 100000,
  unit = "ms"
)

print(results)
boxplot(results, names=c('fast', 'slow'))

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

plot(fast$sun_illuminance, slow$sun_illuminance)
abline(0,1)

plot(fast$moon_illuminance, slow$moon_illuminance)
abline(0,1)

plot(fast$total_illuminance, slow$total_illuminance)
abline(0,1)

plot(fast$sun_azimuth, slow$sun_azimuth)
abline(0,1)

plot(fast$sun_altitude, slow$sun_altitude)
abline(0,1)

plot(fast$moon_azimuth, slow$moon_azimuth)
abline(0,1)

plot(fast$moon_altitude, slow$moon_altitude)
abline(0,1)

plot(fast$moon_fraction, slow$moon_fraction)
abline(0,1)


