#' Sky illuminance values for the sun and moon
#'
#' Function returns sky illuminance parameters for
#' both the sun and the moon, in addition to some
#' ancillary parameters such as sun and moon azimuth
#' and altitude.
#'
#' The code is almost verbatim transcription of the work
#' "Computer Programs for Sun and Moon Illuminance
#' With Contingent Tables and Diagrams by Janiczek and DeYoung"
#' and published in the US Naval observatory circular nr. 171, 1987.
#'
#' Required parameters are a location (in longitude, latitude),
#' and a date in POSIXct format set to the GMT/UTC time zone.
#' Conversions to GMT/UTC should be done externally, errors
#' are not trapped.
#'
#' The original code has been vectorized, as such vectors of
#' location, time and/or sky conditions can be provided.
#'
#' @param .data A data frame or data frame extension (e.g. a tibble) with
#'  named columns: longitude, latitude, date and optionally sky_condition
#' @param longitude decimal longitude (single value or vector of values)
#' @param latitude decimal latitude (single value or vector of values)
#' @param date date and time in POSIXct format with GMT/UTC as time zone
#'  (single value or vector of values)
#' @param sky_condition a positive value (>=1) with which to scale
#'  illuminance values (1 = cloud cover < 30%, 2 = thin veiled clouds
#'  3 = average clouds, 10 = dark stratus clouds). By and large this
#'  can be considered a scaling factor, substituting it with the (inverse)
#'  slope parameter of an empirical fit should render more accurate results.
#'  (this can be a single value or vector of values)
#'  @param fast fast processing
#'
#' @return Sun and moon illuminance values (in lux), as well as their respective
#' location in the sky (altitude, azimuth).
#'
#' @export
#' @examples
#'
#'  # run the function on standard
#'  # input variables (single values or vectors of equal size)
#'  df <- skylight(
#'   longitude = -135.8,
#'   latitude = -23.4,
#'   date = as.POSIXct("1986-12-18 21:00:00", tz = "GMT"),
#'   sky_condition = 1
#'  )
#'
#'  print(df)
#'
#'  # create data frame of input variables
#'  input <- data.frame(
#'    longitude = 0,
#'    latitude = 50,
#'    date =  as.POSIXct("2020-06-18 00:00:00", tz = "GMT") + seq(0, 1*24*3600, 1800),
#'    sky_condition = 1
#'   )
#'
#'   # calculate on data frame
#'   df <- skylight(input)
#'
#'   print(df)
#'
#'   # the above statement can also be used
#'   # in a piped fashion in R >= 4.2
#'   # input |> skylight()
#'

skylight <- function(
    .data,
    longitude,
    latitude,
    date,
    sky_condition = 1,
    fast = FALSE
    ){

  # pipe friendly function checks
  if(!missing(.data)){

    # check if all required variables
    # are there
    if(all(c("longitude", "latitude", "date") %in% colnames(.data))){
      longitude <- .data$longitude
      latitude <- .data$latitude
      date <- .data$date
    } else {
      stop(
      "
      Did you forget to name your input variables?

      Otherwise, a parameter is missing from your
      piped data frame. Check if your data frame contains:

      - longitude
      - latitude
      - date

      columns (with lower case leters)!
      ")
    }

    # defaulting to sky_conditions = 1
    # if not there
    if("sky_condition" %in% colnames(.data)){
      sky_condition <- .data$sky_condition
    } else {
      message("No sky condition provided, using the default value (1)!")
    }
  }

  # parameter conversions
  year <- as.numeric(format(date,"%Y"))
  month <- as.numeric(format(date,"%m"))
  day <- as.numeric(format(date,"%d"))
  hour <- as.numeric(format(date,"%H"))
  minutes <- as.numeric(format(date, "%M"))

  if (fast) {

    forcing = data.frame(
        longitude = longitude,
        latitude = latitude,
        year = year,
        month = month,
        day = day,
        hour = hour,
        minutes = minutes,
        sky_condition = sky_condition
    )

    # C wrapper call
    output <- .Call(
      'c_skylight_f',
      forcing = as.matrix(forcing),
      n = as.integer(nrow(forcing))
    )

    output <- matrix(output, nrow(forcing), 8, byrow = FALSE)
    colnames(output) <- c("sun_azimuth","sun_altitude", "sun_illuminance",
                       "moon_azimuth", "moon_altitude", "moon_illuminance",
                       "moon_fraction","total_illuminance")

    return(data.frame(output))
  } else {

    # calculate hours as a decimal number
    hour_dec <- hour + minutes/60

    # constant values
    RD <- 57.29577951
    DR <- 1 / RD
    CE <- 0.91775
    SE <- 0.39715

    # convert latitude
    latitude <-  latitude * DR

    J <- 367 * year -
      as.integer(7 * (year + as.integer((month + 9)/12))/4) +
      as.integer(275 * month/9) +
      day - 730531

    E <- hour_dec/24
    D <- J - 0.5 + E

    #---- calculate solar parameters ----
    solar_parameters <- sun(
      D,
      DR,
      RD,
      CE,
      SE
    )

    # in place adjustments
    solar_parameters$T <- solar_parameters$T + 360 * E + longitude
    solar_parameters$H <- solar_parameters$T - solar_parameters$AS

    # calculate celestial body
    # parameters all these subroutines
    # need proper clarifications as
    # not provided in the original work
    # and taken as is
    altaz_parameters <- altaz(
      solar_parameters$DS,
      solar_parameters$H,
      solar_parameters$SD,
      cos(latitude),
      sin(latitude),
      DR,
      RD
    )

    H <- altaz_parameters$H
    Z <- altaz_parameters$H * DR
    solar_azimuth <- altaz_parameters$AZ

    # solar altitude calculation
    solar_altitude <- refr(
      altaz_parameters$H,
      DR
      )

    # atmospheric calculations
    # look up references
    M <- atmos(
      solar_altitude,
      DR
    )

    # Solar illuminance in lux, scaled using the value
    # provided by sky_condition. The default does not
    # scale the value, all other values > 1 scale the
    # illuminance values
    solar_illuminance <- 133775 * M / sky_condition

    #---- calculate lunar parameters ----
    lunar_parameters <- moon(
      D,
      solar_parameters$G,
      CE,
      SE,
      RD,
      DR
    )

    lunar_parameters$H <- solar_parameters$T - lunar_parameters$AS

    altaz_parameters <- altaz(
      lunar_parameters$DS,
      lunar_parameters$H,
      lunar_parameters$SD,
      cos(latitude),
      sin(latitude),
      DR,
      RD
    )

    # corrections?
    Z <- altaz_parameters$H * DR
    H <- altaz_parameters$H - 0.95 * cos(altaz_parameters$H * DR)

    # calculate lunar altitude
    lunar_altitude <- refr(H, DR)

    # atmospheric conditions?
    M <- atmos(lunar_altitude, DR)

    E <- acos(cos(lunar_parameters$V - solar_parameters$LS) * lunar_parameters$CB)
    P <- 0.892 * exp(-3.343/((tan(E/2.0))^0.632)) + 0.0344 * (sin(E) - E * cos(E))
    P <- 0.418 * P/(1 - 0.005 * cos(E) - 0.03 * sin(Z))

    # Lunar illuminance in lux, scaled using the value
    # provided by sky_condition. The default does not
    # scale the value, all other values > 1 scale the
    # illuminance values
    lunar_illuminance <- P * M / sky_condition

    # Lunar azimuth/altitude in degrees
    # again forced to integers seems
    # check if this requirement can be dropped
    lunar_azimuth <- altaz_parameters$AZ

    # The percentage of the moon illuminated
    lunar_fraction <- 50 * (1 - cos(E))

    # Total sky illuminance, this value is of importance when
    # considering dusk/dawn conditions mostly, i.e. during hand-off
    # between solar and lunar illumination conditions
    total_illuminance <- solar_illuminance + lunar_illuminance + 0.0005 / sky_condition
  }

  # format output data frame
  output <- data.frame(
    sun_azimuth = solar_azimuth,
    sun_altitude = solar_altitude,
    sun_illuminance = solar_illuminance,
    moon_azimuth = lunar_azimuth,
    moon_altitude = lunar_altitude,
    moon_illuminance = lunar_illuminance,
    moon_fraction = lunar_fraction,
    total_illuminance = total_illuminance
  )

  # pipe friendly data return
  # if piped data is provided otherwise
  # return plain data frame
  if(!missing(.data)){
    return(cbind(.data, output))
  } else {
    # return a data frame
    return(output)
  }
}
