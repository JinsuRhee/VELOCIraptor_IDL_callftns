!234567
      Subroutine f_rdgal(larr, darr, dir)

      Use omp_lib
      Use HDF5

      Implicit none

      Integer(kind=4) larr(20)
      Real(kind=8) darr(20)

      Character*(larr(11)) dir
! Local Variables

      Integer(kind=4) i, j, k, error
      Integer(kind=4) n_snap, n_thread, n_gal

      Integer(hid_t) :: file_id,dset_id,dspace_id
      Integer(hsize_t), dimension(1) :: dims,maxdims

      Character*(20) fname(larr(3)), galname, dsetname
      Logical ok
      n_snap    = larr(1)
      n_thread  = larr(2)
      n_gal     = larr(3)

      ! File Lists
      i = 1
      j = 0
   10 Continue   
        Write(galname,'(I6.6)') i
        Inquire(file= &
          TRIM(dir)//'GAL_'//TRIM(galname)//'.hdf5', exist = ok)
        If(ok) Then
          j = j+1
          Fname(j) = 'GAL_'//TRIM(galname)//'.hdf5'
        Endif
        i = i+1
        If(j .eq. n_gal) Goto 20
        Goto 10
   20 Continue

      ! Mass First

      CALL h5open_f(error)

      !dsetname = '/G_Prop/G_Mass_tot'
      !Do i=1, 1!n_gal
      !  Call h5fopen_f(fname(i), H5F_ACC_RDONLY_F, file_id, error)
      !  Call h5dopen_f(file_id, dsetname, dset_id, error)
      !  Call h5dget_space_f(dset_id,dspace_id,error)

      !  Call h5sget_simple_extent_dims_f(dspace_id, dims, maxdims, error)
      !  print *, dims, maxdims
      !Enddo



      Return
      End
