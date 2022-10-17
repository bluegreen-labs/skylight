
test_that("check skylight function against known outputs", {

  # create a local mean date, corrected by longitude
  d <- as.POSIXct("1988-08-13 18:31:00", tz = "GMT")

  # longitude correction
  d <- d - 39.5 * (60*60)/15

  vectorized_output <- round(
    skylight(
      c(-135.8, 39.5),
      c(-23.4, 21.3),
      c(as.POSIXct("1986-12-18 21:00:00", tz = "GMT"),
        d
      ),
      c(1,1)
    )
  )

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

  expect_equal(vectorized_output, reference)
})
