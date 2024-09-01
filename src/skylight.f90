module skylight_r_mod

  use, intrinsic :: iso_c_binding, only: c_double, c_int, c_char, c_bool
  implicit none

  private
  public :: skylight_f

  ! set input output data types
  type skylight_forcing
    real(kind=sp) :: longitude
    real(kind=sp) :: latitude
    real(kind=sp) :: date
    real(kind=sp) :: year
    real(kind=sp) :: month
    real(kind=sp) :: day
    real(kind=sp) :: hour
    real(kind=sp) :: minutes
    real(kind=sp) :: sky_conditions
  end type skylight_forcing

  type skylight_output
    real(kind=sp) :: solar_azimuth
    real(kind=sp) :: solar_altitude
    real(kind=sp) :: solar_illuminance
    real(kind=sp) :: lunar_azimuth
    real(kind=sp) :: lunar_altitude
    real(kind=sp) :: lunar_illuminance
    real(kind=sp) :: lunar_fraction
    real(kind=sp) :: total_illuminance
  end type skylight_output

  subroutine skylight_f( &
    forcing, &
    output &
    ) bind(C, name = "skylight_f_")

    use subroutines

    integer :: n
    real(kind=dp),  dimension(n, 9), intent(in)  :: forcing
    type(skylight_forcing), dimension(n, 9) :: input
    type(skylight_output), dimension(n, 8), intent(out) :: output

    ! warning: column indices in forcing array are hard coded
    input(:)%longitude   = real(forcing(:, 1))
    input(:)%latitude   = real(forcing(:, 2))
    input(:)%date   = real(forcing(:, 3))
    input(:)%year    = real(forcing(:, 4))
    input(:)%month    = real(forcing(:, 5))
    input(:)%day    = real(forcing(:, 6))
    input(:)%hour    = real(forcing(:, 7))
    input(:)%minutes    = real(forcing(:, 8))
    input(:)%sky_conditions    = real(forcing(:, 9))

    integer :: year, month, day, hour, minutes
    real :: hour_dec, RD, DR, CE, SE, latitude, J, E, solar_altitude, lunar_altitude, M, P, Z

    ! Constant values
    RD = 57.29577951
    DR = 1.0 / RD
    CE = 0.91775
    SE = 0.39715

    hour_dec = hour + minutes / 60.0

    ! Convert latitude
    latitude = input%latitude * DR

    ! Julian day calculation
    J = 367 * int(input%year) - int(7 * (input%year + int((input%month + 9) / 12)) / 4) + &
        int(275 * input%month / 9) + day - 730531

    E = hour_dec / 24.0
    D = J - 0.5 + E

    ! Calculate solar parameters
    call sun( &
            D, &
            DR, &
            RD, &
            CE, &
            SE, &
            output
            )

    ! In-place adjustments (UTTER LLM BULLSHIT, double ckeck everything)
    output%sun_azimuth = output%sun_azimuth + 360 * E + output%longitude
    output%sun_altitude = output%sun_azimuth - output%sun_illuminance

    ! Calculate celestial body parameters
    call altaz( &
          output%sun_altitude, &
          output%sun_azimuth, &
          output%sun_illuminance, &
          cos(latitude), &
          sin(latitude), &
          DR, &
          RD, &
          Z, &
          output%moon_azimuth &
        )

    ! Solar altitude calculation
    call refr(output%sun_altitude, DR, output%sun_altitude)

    ! Atmospheric calculations
    call atmos(output%sun_altitude, DR, M)

    ! Solar illuminance
    output%sun_illuminance = 133775 * M / input%sky_condition

    ! Calculate lunar parameters
    call moon( &
          D, &
          output%sun_azimuth, &
          CE, &
          SE, &
          RD, &
          DR, &
          output%moon_azimuth, &
          output%moon_altitude, &
          output%moon_illuminance, &
          output%moon_fraction &
        )

    ! Lunar altazimuth
    call altaz( &
          output%moon_altitude, &
          output%moon_azimuth, &
          output%moon_illuminance, &
          cos(latitude), &
          sin(latitude), &
          DR, &
          RD, &
          Z, &
          output%moon_azimuth &
        )

    ! Lunar altitude
    call refr( &
          output%moon_altitude, &
          DR, &
          output%moon_altitude &
        )

    ! Atmospheric conditions
    call atmos( &
          output%moon_altitude, &
          DR, &
          M &
        )

    ! Lunar illuminance
    output%moon_illuminance = P * M / input%sky_condition

    ! Total illuminance
    output%total_illuminance = output%sun_illuminance + output%moon_illuminance + 0.0005 / input%sky_condition

  end subroutine skylight_f

end module skylight_r_mod
