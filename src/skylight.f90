module skylight_r_mod
  use, intrinsic :: iso_c_binding

  implicit none

  private
  public :: skylight_f

contains

  subroutine skylight_f( &
    forcing, &
    n, &
    output &
    ) bind(C, name = "skylight_f_")

    use subroutines
    implicit none

    integer(kind = c_int), intent(in)  :: n
    real(kind = c_double), intent(in), dimension(n, 8) :: forcing
    real(kind = c_double), intent(out), dimension(n, 8) :: output

    ! internal state variables (i.e. subroutine output)
    real, dimension(n) :: T, G, LS, AS, SD, DS, V, &
      CB, H, CI, SI, HA, D, E, J, AZ, Z, M, P

    real, dimension(n) :: longitude, latitude, year, month, day, &
      hour, minutes, sky_conditions, solar_azimuth, solar_altitude, &
      hour_dec, solar_illuminance, lunar_illuminance, lunar_altitude, &
      lunar_fraction, lunar_azimuth, total_illuminance

    ! assign constants
    real :: RD, DR, CE, SE

    ! Constant values
    RD = 57.29577951
    DR = 1.0 / RD
    CE = 0.91775
    SE = 0.39715

    longitude = real(forcing(:, 1))
    latitude = real(forcing(:, 2))
    year = real(forcing(:, 3))
    month = real(forcing(:, 4))
    day = real(forcing(:, 5))
    hour = real(forcing(:, 6))
    minutes = real(forcing(:, 7))
    sky_conditions = real(forcing(:, 8))

    ! calculate decimal hours
    hour_dec = (hour + minutes) / 60.0

    ! Convert latitude
    latitude = latitude * DR

    ! Julian day calculation
    J = 367 * int(year) - int(7 * (year + int((month + 9) / 12)) / 4) + &
        int(275 * month / 9) + int(day) - 730531

    E = hour_dec / 24.0
    D = J - 0.5 + E

    !------------- SUN routines ------------------------

    ! Calculate solar parameters returning second line values
    call sun(D, DR, RD, CE, SE, T, G, LS, AS, SD, DS)

    ! In-place adjustments (UTTER LLM BULLSHIT, double ckeck everything)
    T = T + (360 * E) + longitude
    H = T - AS

    call altaz(DS, H, SD, cos(latitude), sin(latitude), DR, RD, AZ)
    Z = H * DR

    ! corrections
    call refr(H, DR, HA)
    solar_altitude = HA
    call atmos(HA, DR, M)

    ! readable output
    solar_azimuth = AZ
    solar_illuminance = (133775 * M) / sky_conditions

    !------------- MOON routines ------------------------
    call moon(D, G, CE, SE, RD, DR, &
              V, SD, AS, DS, CB &
              )

    ! reclycling parameters NOT SAFE
    H = T - AS

    call altaz(DS, H, SD, cos(latitude), sin(latitude), DR, RD, AZ)
    Z = H * DR
    H = H - 0.95 * cos(Z)

    call refr(H, DR, HA)
    lunar_altitude = HA
    call atmos(HA, DR, M)

    E = acos(cos(V - LS) * CB)
    P = 0.892 * exp(-3.343/((tan(E/2.0))**0.632)) + 0.0344 * (sin(E) - E * cos(E))
    P = 0.418 * P/(1 - 0.005 * cos(E) - 0.03 * sin(Z))

    lunar_illuminance = P * M / sky_conditions
    lunar_azimuth = AZ
    lunar_fraction = 50 * (1 - cos(E))

    !------------- OUTPUT routines ------------------------

    ! Total illuminance
    total_illuminance = solar_illuminance + lunar_illuminance + 0.0005 / sky_conditions

    ! assign T
    output(:,1) = solar_azimuth
    output(:,2) = solar_altitude
    output(:,3) = solar_illuminance
    output(:,4) = lunar_azimuth
    output(:,5) = lunar_altitude
    output(:,6) = lunar_illuminance
    output(:,7) = lunar_fraction
    output(:,8) = total_illuminance

  end subroutine skylight_f

end module skylight_r_mod
