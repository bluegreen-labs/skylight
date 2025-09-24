Dear CRAN team,

This new version of {skylight} now uses a C++ version of the previous R code base. This increases speed for small to medium data queries (~100s of values) which allows the code to be efficiently used in inverse modelling of locations based daily sky illuminance data, within the context of geolocation and biologging. All outputs were verified and remain on parity with published (and previous) values.

Kind regards,
Koen Hufkens

I have read and agree to the the CRAN policies at
http://cran.r-project.org/web/packages/policies.html

## test environments, local, CI and r-hub

- Ubuntu 22.04 install on R 4.5
- Ubuntu 22.04 on github actions (devel / release)
- MacOS (release)
- codecove.io code coverage at 100%

## local R CMD check results (as cran)

0 errors | 0 warnings | 0 notes
