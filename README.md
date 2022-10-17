# Sky Illuminance <a href='https://github.com/bluegreen-labs/skylight'><img src='logo.png' align="right" height="139" /></a>

[![R-CMD-check](https://github.com/bluegreen-labs/skylight/workflows/R-CMD-check/badge.svg)](https://github.com/bluegreen-labs/skylight/actions)
[![codecov](https://codecov.io/gh/bluegreen-labs/skylight/branch/main/graph/badge.svg?token=ZI3BYIG3MI)](https://codecov.io/gh/bluegreen-labs/skylight)
[![CRAN\_Status\_Badge](https://www.r-pkg.org/badges/version/skylight)](https://cran.r-project.org/package=skylight)
[![](https://cranlogs.r-pkg.org/badges/skylight)](https://cran.r-project.org/package=skylight)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.6527639.svg)](https://doi.org/10.5281/zenodo.6527638)

The skylight package returns sky illuminance parameters for both the sun and 
the moon, for a given date/time and locaion. In addition to some ancillary 
parameters such as sun and moon azimuth and altitude.

The code is an almost verbatim transcription of the work by Janiczek and DeYoung
(1987), published in the US Naval observatory circular. An online copy of this
manuscripts can be found on the internet archive 
(<https://archive.org/details/DTIC_ADA182110>)

Very few adjustments to the original code where made to ensure parity. As such,
most of the naming of the subroutines was retained. However, some changes were
made to the main routine and some aspects of the subroutines to ensure 
vectorization of the code so speed up batch processing of data. 

With time more detailed information will be added to all functions, including 
references to subroutine functions and more transparent variable names, while
limiting variable recycling (a common practice in this code base). As it stands
the code delivers parity with the programme certification values published in 
Table A of Janiczek and DeYoung (1987). These values are used in unit testing.

## How to cite this package in your article

> Koen Hufkens. (2022). bluegreen-labs/skylight: skylight CRAN release v1.0 (v1.0). Zenodo. <https://doi.org/10.5281/zenodo.xxxx>

## Installation

### stable release

To install the current stable release use a CRAN repository:

```r
install.packages("skylight")
library("skylight")
```

### development release

To install the development releases of the package run the following
commands:

``` r
if(!require(devtools)){install.packages("devtools")}
devtools::install_github("bluegreen-labs/skylight")
library("skylight")
```

Vignettes are not rendered by default, if you want to include additional
documentation please use:

``` r
if(!require(devtools)){install.packages("devtools")}
devtools::install_github("bluegreen-labs/skylight", build_vignettes = TRUE)
library("skylight")
```

## Use
### Single date/time and location

skylight values can be calculated for a single point and date using the below call. This will generate a data frame with model values.

```r
single_date <- skylight(

)
```

### Multiple dates/times and/or locations

The skylight function is vectorized, so you can provide vectors of input parameters instead of using a loop and the above function call.

```r
# Generate a dataset with 15 minute values
# for approximately two months
input <- data.frame(
  longitude = 0,
  latitude = 50,
  date =  as.POSIXct("2020-06-18 00:00:00", tz = "GMT") + seq(0, 60*24*3600, 900),
  sky_conditions = 1
)

# calculate sky illuminance values for
# a single date/time and location
df <- skylight(
      input$longitude,
      input$latitude,
      input$date,
      1
    )

print(head(df))

# previous results are of the same dimension (rows)
# as the input data and can be bound together
# for easy plotting
input <- cbind(input, df)
```

Plotting this data results in 

![](https://bluegreen-labs.github.io/skylight/articles/skylight_files/figure-html/unnamed-chukn-3-1.png)

## Licensing

The `skylight` package is distributed under a AGPLv3 license, while the skylight model code resides in the public domain made available by Janiczek and DeYoung (1987). The logo is in part based upon Emoji One v2.0 iconography data.

## References

- Janiczek and DeYoung (1997). [Computer Programs for Sun and
 Moon Illuminance With Contingent Tables and Diagrams](https://archive.org/details/DTIC_ADA182110),
 US Naval observatory circular nr. 171, 1987
 
