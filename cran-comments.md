Dear CRAN team,

This update of {skylight} is a small fix in the parameter check routines. One of these checks, in an edge case, would spam the command line with warning messages. The message has been removed and the default behaviour is now clarified in the documentation instead.

No other changes were made.

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
