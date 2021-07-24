!234567
      SUBROUTINE f_rdgas(larr, darr, dx, x, y, z, val, map)

      USE omp_lib
      IMPLICIT NONE
      INTEGER(KIND=4) larr(20)
      REAL(KIND=8) darr(20)

      REAL(KIND=8) dx(larr(1)), x(larr(1)), y(larr(1)), z(larr(1))
      REAL(KIND=8) mass(larr(1)), val(larr(1), 3)      ! DEN, TEMP, METAL
      REAL(KIND=4) map(larr(2),larr(2))

!!!!!
!! LOCAL VARIABLES
!!!!!
      INTEGER(KIND=4) i, j, k, n_pix
      INTEGER(KIND=4) j0,j1,k0,k1,ncell
      REAL(KIND=8) mindx
      REAL(KIND=4) mapN(larr(2),larr(2))
      REAL(KIND=8) nhterm1, mtest
      REAL(KIND=8) x0, x1, y0, y1, z0, z1, vfrac, mdum
      INTEGER(KIND=4) nx0, nx1, ny0, ny1
      INTEGER(KIND=4) n_thread
      REAL(KIND=8) xr(2), yr(2), zr(2)

      mindx = darr(1)
      ncell = larr(1)
      n_pix = larr(2)
      n_thread = larr(3)
      map = 0.
      mapN = 0.

      xr(1) = darr(11)
      xr(2) = darr(12)
      yr(1) = darr(13)
      yr(2) = darr(14)
      zr(1) = darr(15)
      zr(2) = darr(16)
      CALL OMP_SET_NUM_THREADS(n_thread)

      !$OMP PARALLEL DO default(shared) &
      !$OMP & private(x0,x1,y0,y1,z0,z1) &
      !$OMP & private(nx0,nx1,ny0,ny1,j,k)
      !!$OMP & reduction(+:map, mapN)
      DO i=1, ncell
        !! Get position of each grid
        x0 = MAX(x(i) - dx(i)/2.,xr(1))
        x1 = MIN(x(i) + dx(i)/2.,xr(2))
        y0 = MAX(y(i) - dx(i)/2.,yr(1))
        y1 = MIN(y(i) + dx(i)/2.,yr(2))
        z0 = MAX(z(i) - dx(i)/2.,zr(1))
        z1 = MIN(z(i) + dx(i)/2.,zr(2))

        !! Get Indicies of each grid point
        nx0 = (x0 - xr(1))/mindx + 1
        nx1 = (x1 - xr(1))/mindx + 1
        ny0 = (y0 - yr(1))/mindx + 1
        ny1 = (y1 - yr(1))/mindx + 1

        nx0 = MAX(nx0, 1); ny0 = MAX(ny0, 1)
        nx1 = MIN(nx1, n_pix); ny1 = MIN(ny1, n_pix)
        !! Make Histogram
        DO j=nx0, nx1
        DO k=ny0, ny1
          map(j,k) = map(j,k) + val(i,larr(20)) * val(i,1) * dx(i) !Density weighted
          mapN(j,k)= mapN(j,k) + val(i,1) * dx(i)
        ENDDO
        ENDDO
      ENDDO
      !$OMP END PARALLEL DO

      !$OMP PARALLEL DO default(shared) &
      !$OMP & private(j) reduction(+:mtest)
      DO i=1, n_pix
        DO j=1, n_pix
          IF(larr(19) .EQ. 1) THEN    !3D Density
            IF(map(i,j) .GT. 0) THEN
              map(i,j) = map(i,j) / mapN(i,j)
            ENDIF
          ENDIF
        ENDDO
      ENDDO
      !$OMP END PARALLEL DO

      RETURN
      END
