#!/usr/bin/env Rscript

#R CMD INSTALL --preclean --no-multiarch --with-keep.source skylight

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

input_quick <- input[1:20,]

# calculate sky illuminance values for
# a single date/time and location
df1 <- skylight(
  input_quick
) |>
  select(
    (starts_with("sun") | starts_with("moon"))
  )

print(head(df1))

# calculate sky illuminance values for
# a single date/time and location
df2 <- skylight(
  input_quick,
  fast = TRUE
) |>
  select(
    (starts_with("sun") | starts_with("moon"))
  )

print(head(df2))

b <- microbenchmark(
  "R" = {skylight(
    input
  )},
  "Fortran" = {skylight(
    input,
    fast = TRUE
  )},
  times = 100
)

par(mfrow = c(3,1))
boxplot(b)

R <- b$time[b$expr == "R"]
hist(log(R))

F <- b$time[b$expr != "R"]
hist(log(F))

# library(profvis)
#
# profvis::profvis({
#   skylight(
#     input,
#     fast = TRUE
#   )
# })
