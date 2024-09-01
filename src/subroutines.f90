module subroutines

contains

! see SUN subroutine on p.21 of
! Computer Programs for Sun and Moon Illuminance
! With Contingent Tables and Diagrams of
! Janiczek and DeYoung, US Naval observatory circular
! nr. 171, 1987

subroutine sun(D, DR, RD, CE, SE, T, G, LS, AS, SD, DS)
  implicit none

  real, intent(in) :: D, DR, RD, CE, SE
  real, intent(out) :: T, G, LS, AS, SD, DS

  real :: T_temp

  T = 280.46 + 0.98565 * D
  T_temp = T / 360.0
  T = T - int(T_temp) * 360.0

  where (T < 0.0)
    T = T + 360.0
  end where

  G = (357.5 + 0.98560 * D) * DR
  LS = (T + 1.91 * sin(G)) * DR
  AS = atan(CE * tan(LS)) * RD
  Y = cos(LS)

  where (Y < 0.0)
    AS = AS + 180.0
  end where

  SD = SE * sin(LS)
  DS = asin(SD)
  T = T - 180.0

end subroutine sun

! see MOON subroutine on p.21 of
! Computer Programs for Sun and Moon Illuminance
! With Contingent Tables and Diagrams of
! Janiczek and DeYoung, US Naval observatory circular
! nr. 171, 1987

subroutine moon(D, G, CE, SE, RD, DR, V, SD, AS, DS, CB)
  implicit none

  real, intent(in) :: D, G, CE, SE, RD, DR
  real, intent(out) :: V, SD, AS, DS, CB

  real :: V_temp

  V = 218.32 + 13.1764 * D
  V_temp = V / 360.0
  V = V - int(V_temp) * 360.0

  where (V < 0.0)
    V = V + 360.0
  end where

  Y = (134.96 + 13.06499 * D) * DR
  O = (93.27 + 13.22935 * D) * DR
  W = (235.7 + 24.38150 * D) * DR
  SB = sin(Y)
  CB = cos(Y)
  X = sin(O)
  S = cos(O)
  SD = sin(W)
  CD = cos(W)
  V = (V + (6.29-1.27 * CD + 0.43 * CB) * SB + (0.66 + 1.27 * CB) * SD - &
          0.19 * sin(G) - 0.23 * X * S) * DR
  Y = ((5.13 - 0.17 * CD) * X + (0.56 * SB + 0.17 * SD) * S) * DR
  SV = sin(V)
  SB = sin(Y)
  CB = cos(Y)
  Q = CB * cos(V)
  P = CE * SV * CB - SE * SB
  SD = SE * SV * CB + CE * SB

  DS = asin(SD)
  AS = atan(P/Q) * RD

  where (Q < 0.0)
    AS = AS + 180.0
  end where

end subroutine moon


! see ALTAZ subroutine on p.22 of
! Computer Programs for Sun and Moon Illuminance
! With Contingent Tables and Diagrams of
! Janiczek and DeYoung, US Naval observatory circular
! nr. 171, 1987

subroutine altaz(DS, H, SD, CI, SI, DR, RD, H_out, AZ_out)
  implicit none

  real, intent(in) :: DS, H, SD, CI, SI, DR, RD
  real, intent(out) :: H_out, AZ_out

  real :: CD, CS, Q, P

  CD = cos(DS)
  CS = cos(H * DR)
  Q = SD * CI - CD * SI * CS
  P = -CD * sin(H * DR)
  AZ_out = atan(P/Q) * RD

  where (Q < 0.0)
    AZ_out = AZ_out + 180.0
  end where

  where (AZ_out < 0.0)
    AZ_out = AZ_out + 360.0
  end where

  AZ_out = int(AZ_out + 0.5)
  H_out = asin(SD * SI + CD * CI * CS) * RD

end subroutine altaz

! see REFR subroutine on p.22 of
! Computer Programs for Sun and Moon Illuminance
! With Contingent Tables and Diagrams of
! Janiczek and DeYoung, US Naval observatory circular
! nr. 171, 1987

subroutine refr(H, DR, HA)
  implicit none

  real, intent(in) :: H, DR
  real, intent(out) :: HA

  where (H < -5.0 / 6.0)
    HA = H
  else
    HA = H + 1.0 / tan((H + 8.6 / (H + 4.42)) * DR) / 60.0
  end where

end subroutine refr

! see ATMOS subroutine on p.22 of
! Computer Programs for Sun and Moon Illuminance
! With Contingent Tables and Diagrams of
! Janiczek and DeYoung, US Naval observatory circular
! nr. 171, 1987


subroutine atmos(HA, DR, M)
  implicit none

  real, intent(in) :: HA, DR
  real, intent(out) :: M

  real :: U, X, S

  U = sin(HA * DR)
  X = 753.66156
  S = asin(X * cos(HA * DR) / (X + 1.0))
  M = X * (cos(S) - U) + cos(S)
  M = exp(-0.21 * M) * U + 0.0289 * exp(-0.042 * M) * &
        (1.0 + (HA + 90.0) * U / 57.29577951)

end subroutine atmos
