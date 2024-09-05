#!/usr/bin/env Rscript

#  R CMD INSTALL --preclean --no-multiarch --with-keep.source skylight

# load the library
library(skylight)
library(tidyr)
library(dplyr)
library(microbenchmark)

input <- data.frame(
  longitude = 0,
  latitude = 50,
  date =  as.POSIXct("2020-06-18 00:00:00", tz = "GMT") + seq(0, 60*24*3600, 900),
  sky_condition = 1
)

microbenchmark(
  "R" = {skylight(
    input
  )},
  "Fortran" = {skylight(
    input,
    fast = TRUE
  )}
)

# calculate sky illuminance values for
# a single date/time and location
df <- skylight(
  input
) |>
  select(
    (starts_with("sun") | starts_with("moon"))
  )

print(head(df))

# calculate sky illuminance values for
# a single date/time and location
df <- skylight(
  input,
  fast = TRUE
) |>
  select(
    (starts_with("sun") | starts_with("moon"))
  )

print(head(df))

library(profvis)

profvis::profvis({
  skylight(
    input,
    fast = TRUE
  )
})
