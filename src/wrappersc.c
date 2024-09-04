#include <R.h>
#include <Rinternals.h>
#include <stdlib.h>
#include <Rmath.h>
#include <R_ext/Rdynload.h>

void F77_NAME(skylight_f)(
    double *input,
    int *n,
    double *output
    );

// C wrapper function, order of arguments is fixed
extern SEXP c_skylight_f(
    SEXP input,
    SEXP n
    ){

    // nr rows
    const int nt = INTEGER(n)[0];

    // Specify output
    // 2nd argument to allocMatrix is number of rows,
    // 3rd is number of columns
    SEXP output = PROTECT( allocMatrix(REALSXP, nt, 8));

    // Fortran subroutine call
    F77_CALL(skylight_f)(
        REAL(input),
        INTEGER(n),
        REAL(output)
        );

    UNPROTECT(1);
    return(output);
};

// Specify number of arguments to C wrapper as the last number here
static const R_CallMethodDef CallEntries[] = {
  {"c_skylight_f", (DL_FUNC) &c_skylight_f, 2},
  {NULL,NULL,0}
};

void R_init_skylight(DllInfo *dll)
{
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
    R_RegisterCCallable("skylight", "c_skylight_f",  (DL_FUNC) &c_skylight_f);
}
