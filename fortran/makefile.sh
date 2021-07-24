#gfortran -fopenmp -fPIC -c match.f90 -o match.o
#gcc -fopenmp -fPIC -c match_c2f.c -o match_c2f.o
#gcc -shared -fopenmp match.o match_c2f.o -o match.so
gfortran -fopenmp -fPIC -fcheck=all -mcmodel=large -c f_rdgas.f90 -o f_rdgas.o
gcc -fopenmp -fPIC -mcmodel=large -c f_rdgas_c2f.c -o f_rdgas_c2f.o
gcc -shared -fopenmp f_rdgas.o f_rdgas_c2f.o -o f_rdgas.so -lgfortran

gfortran -fopenmp -fPIC -mcmodel=large -c get_ptcl.f90 -o get_ptcl.o
gcc -fopenmp -fPIC -mcmodel=large -c get_ptcl_c2f.c -o get_ptcl_c2f.o
gcc -shared -fopenmp get_ptcl.o get_ptcl_c2f.o -o get_ptcl.so -lgfortran

gfortran -fopenmp -fPIC -c get_flux.f90 -o get_flux.o
gcc -fopenmp -fPIC -c get_flux_c2f.c -o get_flux_c2f.o
gcc -shared -fopenmp get_flux.o get_flux_c2f.o -o get_flux.so -lgfortran

gfortran -fopenmp -fPIC -c find_domain.f90 -o find_domain.o
gcc -fopenmp -fPIC -c find_domain_c2f.c -o find_domain_c2f.o
gcc -shared -fopenmp find_domain.o find_domain_c2f.o -o find_domain.so -lgfortran

gfortran -fopenmp -fPIC -c prop_time.f90 -o prop_time.o
gcc -fopenmp -fPIC -c prop_time_c2f.c -o prop_time_c2f.o
gcc -shared -fopenmp prop_time.o prop_time_c2f.o -o prop_time.so -lgfortran

gfortran -I /usr/lib/x86_64-linux-gnu/hdf5/serial/include -fopenmp -fPIC -c f_rdgal_d.f90 -o f_rdgal_d.o
h5cc -I /usr/lib/x86_64-linux-gnu/hdf5/serial/include -fopenmp -fPIC -c f_rdgal_d_c2f.c -o f_rdgal_d_c2f.o
h5cc -I /usr/lib/x86_64-linux-gnu/hdf5/serial/include -shared -fopenmp f_rdgal_d.o f_rdgal_d_c2f.o -o f_rdgal_d.so -lgfortran

chmod 777 *.o *.so


