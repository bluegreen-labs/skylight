#include <R.h>
#include <Rinternals.h>
#include <stdlib.h>
#include <Rmath.h>
#include <R_ext/Rdynload.h>

void F77_NAME(skylight_f)(
    double *longitude,
    double *latitude,
    double *altitude,
    double *whc,
    double *par,
    double *forcing,
    double *output
    );

// C wrapper function, order of arguments is fixed
extern SEXP skylight_C(
    SEXP longitude,
    SEXP latitude,
    SEXP altitude,
    SEXP n
    ){

    // Number of time steps (same in forcing and output)
    const int nt = INTEGER(n)[0] ;

    // Specify output
    // 2nd argument to allocMatrix is number of rows,
    // 3rd is number of columns
    SEXP output = PROTECT( allocMatrix(REALSXP, nt, 19) );

    // Fortran subroutine call
    F77_CALL(pmodel_f)(
        REAL(longitude),
        REAL(latitude),
        REAL(altitude),
        INTEGER(n),
        REAL(output)
        );

    UNPROTECT(1);

    return output;
};

// Specify number of arguments to C wrapper as the last number here
static const R_CallMethodDef CallEntries[] = {
  {"skylight_C", (DL_FUNC) &skylight_C, 23},
  {NULL,NULL,0}
};

void R_init_rsofun(DllInfo *dll)
{
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
    R_RegisterCCallable("skylight_C", "skylight_C",  (DL_FUNC) &skylight_C);
}
