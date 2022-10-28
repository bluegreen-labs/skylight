# see SUN subroutine on p.21 of
# Computer Programs for Sun and Moon Illuminance
# With Contingent Tables and Diagrams of
# Janiczek and DeYoung, US Naval observatory circular
# nr. 171, 1987

sun <- function(D, DR, RD, CE, SE){
  T <- 280.46 + 0.98565 * D
  T <- T - as.integer(T/360) * 360

  # vectorize using ifelse statement
  T <- ifelse(T < 0, T + 360, T)

  G <- (357.5 + 0.98560 * D) * DR
  LS <- (T + 1.91 * sin(G)) * DR
  AS <- atan(CE * tan(LS)) * RD
  Y <- cos(LS)

  # vectorize using ifelse statement
  AS <- ifelse(Y < 0, AS + 180, AS)

  SD <- SE * sin(LS)
  DS <- asin(SD)
  T <- T - 180

  return(
    data.frame(
      T,
      G,
      LS,
      AS,
      SD,
      DS
    )
  )
}

# see MOON subroutine on p.21 of
# Computer Programs for Sun and Moon Illuminance
# With Contingent Tables and Diagrams of
# Janiczek and DeYoung, US Naval observatory circular
# nr. 171, 1987

moon <- function(D, G, CE, SE, RD, DR){
  V <- 218.32 + 13.1764 * D
  V <- V - as.integer(V/360) * 360

  # vectorize using ifelse statement
  V <- ifelse(V < 0, V + 360, V)

  Y <- (134.96 + 13.06499 * D) * DR
  O <- (93.27 + 13.22935 * D) * DR
  W <- (235.7 + 24.38150 * D) * DR
  SB <- sin(Y)
  CB <- cos(Y)
  X <- sin(O)
  S <- cos(O)
  SD <- sin(W)
  CD <- cos(W)
  V <- (V + (6.29-1.27 * CD + 0.43 * CB) * SB + (0.66 + 1.27 * CB) * SD -
          0.19 * sin(G) - 0.23 * X * S) * DR
  Y <- ((5.13 - 0.17 * CD) * X + (0.56 * SB + 0.17 * SD) * S) * DR
  SV <- sin(V)
  SB <- sin(Y)
  CB <- cos(Y)
  Q <- CB * cos(V)
  P <- CE * SV * CB - SE * SB
  SD <- SE * SV * CB + CE * SB
  DS <- asin(SD)
  AS <- atan(P/Q) * RD

  # vectorize using ifelse statement
  AS <- ifelse(Q < 0, AS + 180, AS)

  return(
    data.frame(
      V,
      SD,
      AS,
      DS,
      CB
    )
  )
}

# see ALTAZ subroutine on p.22 of
# Computer Programs for Sun and Moon Illuminance
# With Contingent Tables and Diagrams of
# Janiczek and DeYoung, US Naval observatory circular
# nr. 171, 1987

altaz <- function(DS, H, SD, CI, SI, DR, RD){

  CD <- cos(DS)
  CS <- cos(H * DR)
  Q <- SD * CI - CD * SI * CS
  P <- -CD * sin(H * DR)
  AZ <- atan(P/Q) * RD

  # vectorize using ifelse statement
  AZ <- ifelse(Q < 0, AZ + 180, AZ)

  # vectorize using ifelse statement
  AZ <- ifelse(AZ < 0, AZ + 360, AZ)

  AZ <- as.integer(AZ + 0.5)
  H <- asin(SD * SI + CD * CI * CS) * RD

  return(
    data.frame(H, AZ)
    )
}

# see REFR subroutine on p.22 of
# Computer Programs for Sun and Moon Illuminance
# With Contingent Tables and Diagrams of
# Janiczek and DeYoung, US Naval observatory circular
# nr. 171, 1987

refr <- function(H,DR){
  # vectorize using ifelse statement
  HA <- ifelse(H < (-5/6),
              H,
              H+1/(tan((H+8.6/(H+4.42))*DR))/60
  )
  return(HA)
}

# see ATMOS subroutine on p.22 of
# Computer Programs for Sun and Moon Illuminance
# With Contingent Tables and Diagrams of
# Janiczek and DeYoung, US Naval observatory circular
# nr. 171, 1987

atmos <- function(HA,DR){
  U <- sin(HA * DR)
  X <- 753.66156
  S <- asin(X * cos(HA * DR)/(X + 1))
  M <- X * (cos(S) - U) + cos(S)
  M <- exp(-0.21 * M) * U + 0.0289 * exp(-0.042 * M) *
    (1 + (HA + 90) * U/57.29577951)
  return(M)
}
