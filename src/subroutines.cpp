#include <RcppArmadillo.h>
// [[Rcpp::depends(RcppArmadillo)]]

using namespace Rcpp;
using namespace std;
using namespace arma;


// [[Rcpp::export]]
DataFrame sun_rcpp(
  arma::vec D,
  double DR,
  double RD,
  double CE,
  double SE
) {
  int n = D.size();

  arma::vec T(n);
  arma::vec G(n);
  arma::vec LS(n);
  arma::vec AS(n);
  arma::vec Y(n);
  arma::vec SD(n);
  arma::vec DS(n);


    T = 280.46 + 0.98565 * D;
    T = T - floor(T / 360) * 360;

    T.elem(find(T < 0)) += 360;
    //if (T < 0) {
    //  T = T + 360;
    //}

    G = (357.5 + 0.98560 * D) * DR;
    LS = (T + 1.91 * sin(G)) * DR;
    AS = atan(CE * tan(LS)) * RD;
    Y = cos(LS);

    AS.elem(find(Y<0)) += 180;
    //if (Y < 0) {
    //  AS = AS + 180;
    //}

    SD = SE * sin(LS);
    DS = asin(SD);
    T = T - 180;

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
  arma::vec D,
  arma::vec G,
  double CE,
  double SE,
  double RD,
  double DR
) {
 int n = D.size();

 arma::vec V(n);
 arma::vec Y(n);
 arma::vec O(n);
 arma::vec W(n);
 arma::vec SB_Y(n);
 arma::vec CB_Y(n);
 arma::vec X(n);
 arma::vec S(n);
 arma::vec SD_W(n);
 arma::vec CD_W(n);
 arma::vec V_new(n);
 arma::vec Y_new(n);
 arma::vec SV(n);
 arma::vec SB_Y_new(n);
 arma::vec CB_Y_new(n);
 arma::vec Q(n);
 arma::vec P(n);
 arma::vec SD_final(n);
 arma::vec DS(n);
 arma::vec AS(n);

   V = 218.32 + 13.1764 * D;
   V = V - floor(V / 360) * 360;
   V.elem(find(V < 0)) += 360;

   Y = (134.96 + 13.06499 * D) * DR;
   O = (93.27 + 13.22935 * D) * DR;
   W = (235.7 + 24.38150 * D) * DR;

   SB_Y = sin(Y);
   CB_Y = cos(Y);
   X = sin(O);
   S = cos(O);
   SD_W = sin(W);
   CD_W = cos(W);

   V_new = (V + (6.29 - 1.27 * CD_W + 0.43 * CB_Y) % SB_Y + (0.66 + 1.27 * CB_Y) % SD_W -
     0.19 * sin(G) - 0.23 * X % S) * DR;
   Y_new = ((5.13 - 0.17 * CD_W) % X + (0.56 * SB_Y + 0.17 * SD_W) % S) * DR;

   SV = sin(V_new);
   SB_Y_new = sin(Y_new);
   CB_Y_new = cos(Y_new);
   Q = CB_Y_new % cos(V_new);
   P = CE * SV % CB_Y_new - SE * SB_Y_new;
   SD_final = SE * SV % CB_Y_new + CE * SB_Y_new;
   DS = asin(SD_final);
   AS = atan(P / Q) * RD;

   AS.elem(find(Q<0)) += 180;

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
  arma::vec DS,
  arma::vec H,
  arma::vec SD,
  double CI,
  double SI,
  double DR,
  double RD
) {
 int n = DS.size();

 arma::vec CD(n);
 arma::vec CS(n);
 arma::vec Q(n);
 arma::vec P(n);
 arma::vec AZ(n);
 arma::vec H_out(n);

 CD = cos(DS);
 CS = cos(H * DR);
 Q = (SD * CI) - (CD * SI) % CS;
 P = -CD % sin(H * DR);
 AZ = atan(P / Q) * RD;

 AZ.elem(find(Q < 0)) += 180;
 AZ.elem(find(AZ < 0)) += 360;

 AZ = floor(AZ + 0.5);
 H_out = asin(SD * SI + (CD * CI) % CS) * RD;

 return DataFrame::create(
   Named("H") = H_out,
   Named("AZ") = AZ
 );
}

// [[Rcpp::export]]
arma::vec refr_rcpp(
  arma::vec H,
  double DR
) {
 int n = H.size();
 arma::vec HA(n);

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
arma::vec atmos_rcpp(
  arma::vec HA,
  double DR
) {
 int n = HA.size();

 arma::vec U(n);
 double X = 753.66156;
 arma::vec S(n);
 arma::vec M(n);

  U = sin(HA * DR);
  S = asin(X * cos(HA * DR) / (X + 1.0));
  M = X * (cos(S) - U) + cos(S);
  M = exp(-0.21 * M) % U + 0.0289 * exp(-0.042 * M) %
     (1.0 + (HA + 90.0) % U / 57.29577951);

 return M;
}
