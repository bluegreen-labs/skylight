
test_that("check skylight function against known outputs", {

  # create a local mean date, corrected by longitude
  d <- as.POSIXct("1988-08-13 18:31:00", tz = "GMT")

  # longitude correction
  d <- d - 39.5 * (60*60)/15

  # format reference data
  reference <- data.frame(
    "sun_azimuth" = c(346,286),
    "sun_altitude" = c(90,0),
    "sun_illuminance" = c(123786,697),
    "moon_azimuth" = c(282,278),
    "moon_altitude" = c(-62,8),
    "moon_illuminance" = c(0,0),
    "moon_fraction" = c(94,1),
    "total_illuminance" = c(123786,697)
  )

  vectorized_output <- round(
    skylight(
      longitude = c(-135.8, 39.5),
      latitude = c(-23.4, 21.3),
      date = c(as.POSIXct("1986-12-18 21:00:00", tz = "GMT"),
        d
      ),
      sky_condition = c(1,1)
    )
  )

  expect_equal(vectorized_output, reference)

})

test_that("piped input tests", {

  input <- data.frame(
    longitude = 0,
    latitude = 50,
    date =  as.POSIXct("2020-06-18 00:00:00", tz = "GMT") + seq(0, 1*24*3600, 1800),
    sky_condition = 1
  )

  # return a data frame if successful
  expect_type(
      skylight(input),
    "list"
    )

  # fail on missing latitude
  expect_error(
     skylight(input[,-2])
    )
})
