#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
DataFrame sun_rcpp(
  NumericVector D,
  double DR,
  double RD,
  double CE,
  double SE
) {
  int n = D.size();

  NumericVector T(n);
  NumericVector G(n);
  NumericVector LS(n);
  NumericVector AS(n);
  NumericVector Y(n);
  NumericVector SD(n);
  NumericVector DS(n);

  for (int i = 0; i < n; ++i) {
    T[i] = 280.46 + 0.98565 * D[i];
    T[i] = T[i] - static_cast<int>(T[i] / 360) * 360;

    if (T[i] < 0) {
      T[i] = T[i] + 360;
    }

    G[i] = (357.5 + 0.98560 * D[i]) * DR;
    LS[i] = (T[i] + 1.91 * sin(G[i])) * DR;
    AS[i] = atan(CE * tan(LS[i])) * RD;
    Y[i] = cos(LS[i]);

    if (Y[i] < 0) {
      AS[i] = AS[i] + 180;
    }

    SD[i] = SE * sin(LS[i]);
    DS[i] = asin(SD[i]);
    T[i] = T[i] - 180;
  }

  return DataFrame::create(
    Named("T") = T,
    Named("G") = G,
    Named("LS") = LS,
    Named("AS") = AS,
    Named("SD") = SD,
    Named("DS") = DS
  );
}

// [[Rcpp::export]]
DataFrame moon_rcpp(
  NumericVector D,
  NumericVector G,
  double CE,
  double SE,
  double RD,
  double DR
) {
 int n = D.size();

 NumericVector V(n);
 NumericVector Y(n);
 NumericVector O(n);
 NumericVector W(n);
 NumericVector SB_Y(n);
 NumericVector CB_Y(n);
 NumericVector X(n);
 NumericVector S(n);
 NumericVector SD_W(n);
 NumericVector CD_W(n);
 NumericVector V_new(n);
 NumericVector Y_new(n);
 NumericVector SV(n);
 NumericVector SB_Y_new(n);
 NumericVector CB_Y_new(n);
 NumericVector Q(n);
 NumericVector P(n);
 NumericVector SD_final(n);
 NumericVector DS(n);
 NumericVector AS(n);

 for (int i = 0; i < n; ++i) {
   V[i] = 218.32 + 13.1764 * D[i];
   V[i] = V[i] - static_cast<int>(V[i] / 360) * 360;

   if (V[i] < 0) {
     V[i] = V[i] + 360;
   }

   Y[i] = (134.96 + 13.06499 * D[i]) * DR;
   O[i] = (93.27 + 13.22935 * D[i]) * DR;
   W[i] = (235.7 + 24.38150 * D[i]) * DR;
   SB_Y[i] = sin(Y[i]);
   CB_Y[i] = cos(Y[i]);
   X[i] = sin(O[i]);
   S[i] = cos(O[i]);
   SD_W[i] = sin(W[i]);
   CD_W[i] = cos(W[i]);

   V_new[i] = (V[i] + (6.29 - 1.27 * CD_W[i] + 0.43 * CB_Y[i]) * SB_Y[i] + (0.66 + 1.27 * CB_Y[i]) * SD_W[i] -
     0.19 * sin(G[i]) - 0.23 * X[i] * S[i]) * DR;
   Y_new[i] = ((5.13 - 0.17 * CD_W[i]) * X[i] + (0.56 * SB_Y[i] + 0.17 * SD_W[i]) * S[i]) * DR;

   SV[i] = sin(V_new[i]);
   SB_Y_new[i] = sin(Y_new[i]);
   CB_Y_new[i] = cos(Y_new[i]);
   Q[i] = CB_Y_new[i] * cos(V_new[i]);
   P[i] = CE * SV[i] * CB_Y_new[i] - SE * SB_Y_new[i];
   SD_final[i] = SE * SV[i] * CB_Y_new[i] + CE * SB_Y_new[i];
   DS[i] = asin(SD_final[i]);
   AS[i] = atan(P[i] / Q[i]) * RD;

   if (Q[i] < 0) {
     AS[i] = AS[i] + 180;
   }
 }

 return DataFrame::create(
   Named("V") = V_new,
   Named("SD") = SD_final,
   Named("AS") = AS,
   Named("DS") = DS,
   Named("CB") = CB_Y_new
 );
}

// [[Rcpp::export]]
DataFrame altaz_rcpp(
  NumericVector DS,
  NumericVector H,
  NumericVector SD,
  double CI,
  double SI,
  double DR,
  double RD
) {
 int n = DS.size();

 NumericVector CD(n);
 NumericVector CS(n);
 NumericVector Q(n);
 NumericVector P(n);
 NumericVector AZ(n);
 NumericVector H_out(n);

 for (int i = 0; i < n; ++i) {
   CD[i] = cos(DS[i]);
   CS[i] = cos(H[i] * DR);
   Q[i] = SD[i] * CI - CD[i] * SI * CS[i];
   P[i] = -CD[i] * sin(H[i] * DR);
   AZ[i] = atan(P[i] / Q[i]) * RD;

   if (Q[i] < 0) {
     AZ[i] = AZ[i] + 180;
   }

   if (AZ[i] < 0) {
     AZ[i] = AZ[i] + 360;
   }

   AZ[i] = static_cast<int>(AZ[i] + 0.5);
   H_out[i] = asin(SD[i] * SI + CD[i] * CI * CS[i]) * RD;
 }

 return DataFrame::create(
   Named("H") = H_out,
   Named("AZ") = AZ
 );
}


// [[Rcpp::export]]
NumericVector refr_rcpp(
  NumericVector H,
  double DR
) {
 int n = H.size();
 NumericVector HA(n);

 for (int i = 0; i < n; ++i) {
   if (H[i] < -5.0 / 6.0) {
     HA[i] = H[i];
   } else {
     HA[i] = H[i] + 1.0 / (tan((H[i] + 8.6 / (H[i] + 4.42)) * DR)) / 60.0;
   }
 }

 return HA;
}


// [[Rcpp::export]]
NumericVector atmos_rcpp(
  NumericVector HA,
  double DR
) {
 int n = HA.size();

 NumericVector U(n);
 double X = 753.66156;
 NumericVector S(n);
 NumericVector M(n);

 for (int i = 0; i < n; ++i) {
   U[i] = sin(HA[i] * DR);
   S[i] = asin(X * cos(HA[i] * DR) / (X + 1.0));
   M[i] = X * (cos(S[i]) - U[i]) + cos(S[i]);
   M[i] = exp(-0.21 * M[i]) * U[i] + 0.0289 * exp(-0.042 * M[i]) *
     (1.0 + (HA[i] + 90.0) * U[i] / 57.29577951);
 }

 return M;
}
