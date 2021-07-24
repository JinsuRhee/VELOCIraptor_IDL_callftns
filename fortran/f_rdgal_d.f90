!234567
      SUBROUTINE f_rdgal_d(larr, darr, gprop, dir, idlist, tmp)

      USE omp_lib
      USE HDF5

      IMPLICIT NONE

      INTEGER(KIND=4) larr(20)
      REAL(KIND=8) darr(20)

      INTEGER(KIND=4) idlist(larr(1))
      CHARACTER*(larr(2)) dir
      CHARACTER*(larr(4)) Gprop

      REAL(KIND=8) tmp(larr(1))

! Local Variables

      INTEGER(KIND=4) i, j, k, error
      INTEGER(KIND=4) n_thread, n_gal

      CHARACTER(LEN=100) fname, galname
      INTEGER(HID_T) :: file_id,dset_id,dspace_id
      INTEGER(HSIZE_T), DIMENSION(1:1) :: dims! = (/larr(1)/)
      !Integer(hsize_t), dimension(1) :: dims,maxdims

      !Character*(20) fname(larr(3)), galname, dsetname
      !Logical ok

      n_thread  = larr(3)
      n_gal     = larr(1)
      dims      = n_gal

      ! File Lists
      i = 1
      j = 0

      !fname, error, file_id, dset_id, dspace_id
      DO i=1, n_gal
        WRITE(galname,'(I6.6)') idlist(i)
        fname = TRIM(dir)//TRIM(galname)//'.hdf5'

        !CALL h5fopen_f(fname, H5F_ACC_RDONLY_F, file_id, error)
        !CALL h5dopen_f(file_id, Gprop, dset_id, error)
        !CALL h5dget_space_f(dset_id,dspace_id, error)
        !CALL h5sget_simple_extent_dims_f(dspace_id, dims, 
        !CALL h5dread_f(dset_id, H5T_NATIVE_INTEGER, tmp, dims, error)
      ENDDO



      ! Mass First

      !CALL h5open_f(error)

      !!dsetname = '/G_Prop/G_Mass_tot'
      !!Do i=1, 1!n_gal
      !!  Call h5fopen_f(fname(i), H5F_ACC_RDONLY_F, file_id, error)
      !!  Call h5dopen_f(file_id, dsetname, dset_id, error)
      !!  Call h5dget_space_f(dset_id,dspace_id,error)

      !!  Call h5sget_simple_extent_dims_f(dspace_id, dims, maxdims, error)
      !!  print *, dims, maxdims
      !!Enddo



      Return
      End
