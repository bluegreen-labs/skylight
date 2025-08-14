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

  forcing <- data.frame(
    longitude = longitude,
    latitude = latitude,
    year = year,
    month = month,
    day = day,
    hour = hour,
    minutes = minutes,
    sky_condition = sky_condition
  )

  output <- skylight_rcpp(
    forcing = as.matrix(forcing)
  )

  colnames(output) <- c(
    "sun_azimuth",
    "sun_altitude",
    "sun_illuminance",
    "moon_azimuth",
    "moon_altitude",
    "moon_illuminance",
    "moon_fraction",
    "total_illuminance"
  )

  # pipe friendly data return
  # if piped data is provided otherwise
  # return plain data frame
  if(!missing(.data)){
    return(cbind(.data, output))
  }

  # return a data frame
  return(as.data.frame(output))
}

.onUnload <- function(libpath) {
  library.dynam.unload("skylight", libpath)
}
