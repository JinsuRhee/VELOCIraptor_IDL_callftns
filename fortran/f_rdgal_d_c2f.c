#include <stdio.h>
#include "hdf5.h"

typedef struct {
   unsigned short slen;         /* length of the string         */
   short stype;                 /* Type of string               */
   char *s;                     /* Pointer to chararcter array  */
} STRING;

#define STR_LEN(__str)    ((long)(__str)->slen)

void f_rdgal_d(int argc, void *argv[])
{
  extern void f_rdgal_d_();   /* FORTRAN routine */
  double *tmp;
  int *idlist;

  STRING *dir, *Gprop; 
  int *larr;
  double *darr;

  char file;
  hid_t fid, did;
  herr_t stat;


  larr		= (int *) argv[0];
  darr		= (double *) argv[1];
  Gprop		= (STRING *) argv[2];
  dir		= (STRING *) argv[3];
  idlist	= (int *) argv[4];
  tmp		= (double *) argv[5];

  f_rdgal_d_(larr, darr, Gprop->s, dir->s, idlist, tmp);   /* Compute sum */
}
