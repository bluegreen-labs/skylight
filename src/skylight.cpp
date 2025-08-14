#include <RcppArmadillo.h>
#include <cmath>
#include "subroutines.h"

// [[Rcpp::depends(RcppArmadillo)]]

// Define constants
const double RD = 57.29577951;
const double DR = 1.0 / RD;
const double CE = 0.91775;
const double SE = 0.39715;

//' fast C++ implementation of the skylight model
//'
//' Calculates sky illuminance values faster. This function
//' should not be called independently and the formal R
//' skylight() function should be used with the parameter
//' fast = TRUE!
//'
//' @param forcing input matrix with forcing parameters organized
//'  as longitude, latitude, year, month, day, hour, minutes,
//'  sky_conditions
//' @return sky illuminance results as a matrix
// [[Rcpp::export]]
arma::mat skylight_rcpp(arma::mat forcing) {

  // ------------- setup -----------------------------
  // forcing input fields in this order
  // longitude
  // latitude
  // year
  // month
  // day
  // hour
  // minutes
  // sky_conditions

  // dimensions of the input matrix
  int n = forcing.n_rows;

  // output matrices final + internal
  arma::mat output(n, 8);
  arma::mat altaz_output(n,2);
  arma::mat sun_output(n, 6);
  arma::mat moon_output(n, 5);

  // state variables
  arma::vec T(n), H(n), Z(n), P(n), E(n), D(n), J(n),
    cos_lat, sin_lat, hour_dec, latitude_dr;

  // output vectors
  arma::vec
    solar_azimuth(n),
    solar_altitude(n),
    solar_illuminance(n),
    lunar_illuminance(n),
    lunar_altitude(n),
    lunar_fraction(n),
    lunar_azimuth(n),
    total_illuminance(n);

  // Calculate decimal hours
  hour_dec = forcing.col(5) + (forcing.col(6) / 60.0);

  // convert latitudes
  latitude_dr = forcing.col(1) * DR;

  // Julian day calculation
  J = 367 * arma::floor(forcing.col(2)) -
    arma::floor(7 * (forcing.col(2) + arma::floor((forcing.col(3) + 9) / 12)) / 4) +
    arma::floor(275 * forcing.col(3) / 9) + forcing.col(4) - 730531;
  E = hour_dec / 24.0;
  D = J - 0.5 + E;

  // precalculate cos/sin conversions
  cos_lat = arma::cos(latitude_dr);
  sin_lat = arma::sin(latitude_dr);

  // ------------- SUN routines ------------------------

  // call sun routine
  // returns in this order: T, G, LS, AS, SD, DS
  sun_output = sun(D, DR, RD, CE, SE);

  // T is carried over to the MOON routine
  T = sun_output.col(0) + (360 * E) + forcing.col(0);

  altaz_output = altaz(
    sun_output.col(5), //DS
    T - sun_output.col(3), //H
    sun_output.col(4), //SD
    cos_lat,
    sin_lat,
    DR,
    RD
  );

  solar_azimuth = altaz_output.col(0);
  solar_altitude = refr(altaz_output.col(1), DR);
  solar_illuminance = 133775 * atmos(solar_altitude, DR) / forcing.col(7);

  // ------------- MOON routines ------------------------

  // moon parameters
  // returns in this order: V, SD, AS, DS, CB (0 indexed)
  moon_output = moon(D, sun_output.col(1), CE, SE, RD, DR);

  altaz_output = altaz(
    moon_output.col(3),
    (T - moon_output.col(2)),
    moon_output.col(1),
    cos_lat,
    sin_lat,
    DR,
    RD
  );

  lunar_azimuth = altaz_output.col(0);
  H = altaz_output.col(1) - (0.95 * arma::cos(altaz_output.col(1) * DR));

  lunar_altitude = refr(H, DR);

  // calculate lunar fraction
  E = arma::acos(arma::cos(moon_output.col(0) - sun_output.col(2)) % moon_output.col(4));
  lunar_fraction = 50.0 * (1 - arma::cos(E));

  // calculate lunar illuminance
  P = 0.892 * arma::exp(-3.343 / arma::pow(arma::tan(E / 2.0), 0.632)) +
    0.0344 * (arma::sin(E) - E % arma::cos(E));
  P = 0.418 * P / (1 - 0.005 * arma::cos(E) - 0.03 * arma::sin(altaz_output.col(1) * DR));
  lunar_illuminance = P % atmos(lunar_altitude, DR) / forcing.col(7);

  // ------------- total illuminance  ----------------------

  total_illuminance = solar_illuminance + lunar_illuminance + 0.0005 / forcing.col(7);

  // ------------- OUTPUT routines ------------------------

  output.col(0) = solar_azimuth;
  output.col(1) = solar_altitude;
  output.col(2) = solar_illuminance;
  output.col(3) = lunar_azimuth;
  output.col(4) = lunar_altitude;
  output.col(5) = lunar_illuminance;
  output.col(6) = lunar_fraction;
  output.col(7) = total_illuminance;

  return output;
}
