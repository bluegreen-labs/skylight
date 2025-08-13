#include <RcppArmadillo.h>
#include <cmath>
#include "subroutines.h"

// [[Rcpp::depends(RcppArmadillo)]]

// Define constants
const double RD = 57.29577951;
const double DR = 1.0 / RD;
const double CE = 0.91775;
const double SE = 0.39715;

// [[Rcpp::export]]
arma::mat skylight_rcpp(arma::mat forcing) {

  // Get dimensions of the input matrix
  int n = forcing.n_rows;

  // Allocate output matrix
  arma::mat output(n, 8);

  // Internal state variables
  arma::vec T(n), G(n), LS(n), AS(n), SD(n), DS(n), V(n), CB(n), H(n),
  CI(n), SI(n), HA(n), AZ(n), Z(n), M(n), P(n), E(n), D(n), J(n);

  // Extract columns from forcing matrix
  // consolidate with direct referencing for speed
  // later
  arma::vec longitude = forcing.col(0);
  arma::vec latitude = forcing.col(1);
  arma::vec year = forcing.col(2);
  arma::vec month = forcing.col(3);
  arma::vec day = forcing.col(4);
  arma::vec hour = forcing.col(5);
  arma::vec minutes = forcing.col(6);
  arma::vec sky_conditions = forcing.col(7);

  // Calculate decimal hours
  arma::vec hour_dec = hour + (minutes / 60.0);

  // Convert latitude to radians
  arma::vec latitude_rad = latitude * DR;

  // Julian day calculation
  J = 367 * arma::floor(year) -
    arma::floor(7 * (year + arma::floor((month + 9) / 12)) / 4) +
    arma::floor(275 * month / 9) + day - 730531;

  E = hour_dec / 24.0;
  D = J - 0.5 + E;

  // Output vectors
  arma::vec solar_azimuth(n), solar_altitude(n), solar_illuminance(n),
  lunar_illuminance(n), lunar_altitude(n), lunar_fraction(n), lunar_azimuth(n),
  total_illuminance(n);

  // ------------- SUN routines ------------------------

  // Placeholder calls for subroutines
  arma::mat sun_output(n, 6);
  sun_output = sun(D, DR, RD, CE, SE);

  T = sun_output.col(0);
  G = sun_output.col(1);
  LS = sun_output.col(2);
  AS = sun_output.col(3);
  SD = sun_output.col(4);
  DS = sun_output.col(5);

  T = T + (360 * E) + longitude;
  H = T - AS;

  arma::vec cos_lat = arma::cos(latitude_rad);
  arma::vec sin_lat = arma::sin(latitude_rad);

  arma::mat altaz_output(n,2);
  altaz_output = altaz(DS, H, SD, cos_lat, sin_lat, DR, RD);

  AZ = altaz_output.col(0);
  H = altaz_output.col(1);

  Z = H * DR;

  HA = refr(H, DR);
  solar_altitude = HA;

  M = atmos(HA, DR);

  solar_azimuth = AZ;
  solar_illuminance = 133775 * M / sky_conditions;

  // ------------- MOON routines ------------------------

  arma::mat moon_output(n, 5);

  moon_output = moon(D, G, CE, SE, RD, DR);

  V = moon_output.col(0);
  SD = moon_output.col(1);
  AS = moon_output.col(2);
  DS = moon_output.col(3);
  CB = moon_output.col(4);

  H = T - AS;

  altaz_output = altaz(DS, H, SD, cos_lat, sin_lat, DR, RD);

  AZ = altaz_output.col(0);
  H = altaz_output.col(1);

  Z = H * DR;
  H = H - (0.95 * arma::cos(Z));

  HA = refr(H, DR);
  lunar_altitude = HA;

  M = atmos(HA, DR);

  E = arma::acos(arma::cos(V - LS) % CB);
  P = 0.892 * arma::exp(-3.343 / arma::pow(arma::tan(E / 2.0), 0.632)) + 0.0344 * (arma::sin(E) - E % arma::cos(E));
  P = 0.418 * P / (1 - 0.005 * arma::cos(E) - 0.03 * arma::sin(Z));

  lunar_illuminance = P % M / sky_conditions;
  lunar_azimuth = AZ;
  lunar_fraction = 50.0 * (1 - arma::cos(E));

  // ------------- OUTPUT routines ------------------------

  total_illuminance = solar_illuminance + lunar_illuminance + 0.0005 / sky_conditions;

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
