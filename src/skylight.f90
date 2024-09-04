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
      CB, H, CI, SI, HA, D, E, J, hour_dec

    real, dimension(n) :: longitude, latitude, year, month, day, &
      hour, minutes, sky_conditions

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
    !latitude = latitude * DR

    ! Julian day calculation
    J = 367 * int(year) - int(7 * (year + int((month + 9) / 12)) / 4) + &
        int(275 * month / 9) + int(day) - 730531

    E = hour_dec / 24.0
    D = J - 0.5 + E

    !------------- SUN routines ------------------------

    ! Calculate solar parameters returning second line values
    call sun(D, DR, RD, CE, SE, T, G, LS, AS, SD, DS)

    ! In-place adjustments (UTTER LLM BULLSHIT, double ckeck everything)
    T = T + 360 * E + longitude
    H = T - AS


    !------------- MOON routines ------------------------




    !------------- OUTPUT routines ------------------------

    ! Total illuminance
    !total_illuminance = sun_illuminance + moon_illuminance + 0.0005 / sky_condition

    ! assign T
    output(:,1) = longitude

  end subroutine skylight_f

end module skylight_r_mod
