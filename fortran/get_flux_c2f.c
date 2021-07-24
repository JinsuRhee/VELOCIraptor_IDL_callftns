#include <stdio.h>

void get_flux(int argc, void *argv[])
{
  extern void get_flux_();   /* FORTRAN routine */

  float *age, *metal;
  float *SSP_age, *SSP_metal, *SSP_wave, *SSP_flux;
  float *TR_wave, *TR_curve;
  double *dbl_set, *mass, *flux;
  int *int_set;

  age		= (float *) argv[0];
  metal		= (float *) argv[1];
  mass		= (double *) argv[2];
  SSP_age	= (float *) argv[3];
  SSP_metal	= (float *) argv[4];
  SSP_wave	= (float *) argv[5];
  SSP_flux	= (float *) argv[6];
  TR_wave	= (float *) argv[7];
  TR_curve	= (float *) argv[8];
  flux		= (double *) argv[9];
  int_set	= (int *) argv[10];
  dbl_set	= (double *) argv[11];

  get_flux_(age, metal, mass, SSP_age, SSP_metal, SSP_wave, SSP_flux, TR_wave, TR_curve, flux, int_set, dbl_set);
}
