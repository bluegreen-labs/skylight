! Defines the main program setup, which will call upon
! different subroutines for flexibility.

module skylight_mod

  implicit none

  ! derive type for data management
  type skylight_data
    real :: longitude, latitude, year, month, day, hour, minutes, sky_condition
    real :: sun_azimuth, sun_altitude, sun_illuminance
    real :: moon_azimuth, moon_altitude, moon_illuminance, moon_fraction
    real :: total_illuminance
  end type skylight_data

  subroutine skylight(data, n_data, output_data) bind(C, name = "skylight_f_")
    implicit none

    type(skylight_data), intent(in) :: data(:)
    integer, intent(in) :: n_data
    type(skylight_data), intent(out) :: output_data(:)

    integer :: year, month, day, hour, minutes
    real :: hour_dec, RD, DR, CE, SE, latitude, J, E, solar_altitude, lunar_altitude, M, P, Z

    ! Constant values
    RD = 57.29577951
    DR = 1.0 / RD
    CE = 0.91775
    SE = 0.39715

    ! Parameter conversions
    do i = 1, n_data

      hour_dec = hour + minutes / 60.0

      ! Convert latitude
      latitude = data(i)%latitude * DR

      ! Julian day calculation
      J = 367 * year - int(7 * (year + int((month + 9) / 12)) / 4) + &
          int(275 * month / 9) + day - 730531

      E = hour_dec / 24.0
      D = J - 0.5 + E

      ! Calculate solar parameters
      call sun(D, DR, RD, CE, SE, output_data(i)%sun_azimuth, output_data(i)%sun_altitude, &
               output_data(i)%sun_illuminance)

      ! In-place adjustments
      output_data(i)%sun_azimuth = output_data(i)%sun_azimuth + 360 * E + data(i)%longitude
      output_data(i)%sun_altitude = output_data(i)%sun_azimuth - output_data(i)%sun_illuminance

      ! Calculate celestial body parameters
      call altaz(output_data(i)%sun_altitude, output_data(i)%sun_azimuth, output_data(i)%sun_illuminance, &
                 cos(latitude), sin(latitude), DR, RD, Z, output_data(i)%moon_azimuth)

      ! Solar altitude calculation
      call refr(output_data(i)%sun_altitude, DR, output_data(i)%sun_altitude)

      ! Atmospheric calculations
      call atmos(output_data(i)%sun_altitude, DR, M)

      ! Solar illuminance
      output_data(i)%sun_illuminance = 133775 * M / data(i)%sky_condition

      ! Calculate lunar parameters
      call moon(D, output_data(i)%sun_azimuth, CE, SE, RD, DR, &
                output_data(i)%moon_azimuth, output_data(i)%moon_altitude, &
                output_data(i)%moon_illuminance, output_data(i)%moon_fraction)

      ! Lunar altazimuth
      call altaz(output_data(i)%moon_altitude, output_data(i)%moon_azimuth, output_data(i)%moon_illuminance, &
                 cos(latitude), sin(latitude), DR, RD, Z, output_data(i)%moon_azimuth)

      ! Lunar altitude
      call refr(output_data(i)%moon_altitude, DR, output_data(i)%moon_altitude)

      ! Atmospheric conditions
      call atmos(output_data(i)%moon_altitude, DR, M)

      ! Lunar illuminance
      output_data(i)%moon_illuminance = P * M / data(i)%sky_condition

      ! Total illuminance
      output_data(i)%total_illuminance = output_data(i)%sun_illuminance + output_data(i)%moon_illuminance + 0.0005 / data(i)%sky_condition
    end do

  end subroutine skylight

end module skylight_module
