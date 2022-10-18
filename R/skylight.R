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
#'
#' @export

skylight <- function(
    .data,
    longitude,
    latitude,
    date,
    sky_condition = 1
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
  time_zone <- as.numeric(format(date, "%z"))/100

  # calculate hours as a decimal number
  hour_dec <- hour + minutes/60

  # hours as a long integer
  H <- hour * 100 + minutes # hhmm (hour)

  # constant values
  RD <- 57.29577951
  DR <- 1.0 / RD
  CE <- 0.91775
  SE <- 0.39715

  # run program
  latitude <-  latitude * DR

  J <- 367 * year -
    as.integer( 7 * (year + as.integer((month + 9)/12))/4) +
    as.integer(275 * month/9) +
    day - 730531

  # DT requires time zone to be UTC/GMT
  DT <- -longitude/360.0

  E <- hour_dec/24.0 - DT - longitude/360.0
  D <- J - 0.5 + E

  #---- calculate solar parameters ----
  solar_parameters <- sun(
    D,
    DR,
    RD,
    CE,
    SE
  )

  solar_parameters$T <- solar_parameters$T + 360.0 * E + longitude
  solar_parameters$H <- solar_parameters$T - solar_parameters$AS

  out_altaz <- altaz(
    solar_parameters$DS,
    solar_parameters$H,
    solar_parameters$SD,
    cos(latitude),
    sin(latitude),
    DR,
    RD
  )

  H <- out_altaz$H
  AZ <- out_altaz$AZ
  Z <- out_altaz$H * DR

  # HERE HA GETS RECYCLED POOR
  # FORM FIX, MESSES UP CALCULATIONS
  # IF NOT PROPERLY ACCOUNTED FOR
  # SAME FOR THE LUNAR STUFF
  # solar altitude calculation
  HA <- refr(
    out_altaz$H,
    DR
    )

  # atmospheric calculations?
  M <- atmos(
    HA,
    DR
  )

  HA <- sign(HA) * as.integer(abs(HA) + 0.5)

  # Solar illuminance in lux, scaled using the value
  # provided by sky_condition. The default does not
  # scale the value, all other values > 1 scale the
  # illuminance values
  solar_illuminance <- 133775.0 * M / sky_condition

  # Solar azimuth in degrees
  solar_azimuth <- as.integer(AZ)

  # Solar altitude in degrees
  solar_altitude <- as.integer(HA)

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

  out_altaz <- altaz(
    lunar_parameters$DS,
    lunar_parameters$H,
    lunar_parameters$SD,
    cos(latitude),
    sin(latitude),
    DR,
    RD
  )

  # corrections?
  Z <- out_altaz$H * DR
  H <- out_altaz$H - 0.95 * cos(out_altaz$H * DR)

  # calculate lunar altitude
  HA <- refr(H, DR)

  # atmospheric conditions?
  M <- atmos(HA, DR)

  HA <- sign(HA)*as.integer(abs(HA)+0.5)
  E <- acos(cos(lunar_parameters$V - solar_parameters$LS) * lunar_parameters$CB)
  P <- 0.892 * exp(-3.343/((tan(E/2.0))^0.632)) + 0.0344 * (sin(E) - E * cos(E))
  P <- 0.418 * P/(1.0-0.005 * cos(E) - 0.03 * sin(Z))

  # Lunar illuminance in lux, scaled using the value
  # provided by sky_condition. The default does not
  # scale the value, all other values > 1 scale the
  # illuminance values
  lunar_illuminance <- P * M / sky_condition

  # Lunar azimuth in degrees
  lunar_azimuth <- as.integer(out_altaz$AZ)

  # Lunar altitude in degrees
  lunar_altitude <- as.integer(HA)

  # The percentage of the moon illuminated
  lunar_fraction <- as.integer(50.*(1.0-cos(E))+0.5)

  # Total sky illuminance, this value is of importance when
  # considering dusk/dawn conditions mostly, i.e. during hand-off
  # between solar and lunar illumination conditions
  total_illuminance <- solar_illuminance + lunar_illuminance + 0.0005 / sky_condition

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
