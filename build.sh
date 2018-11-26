#!/bin/bash

# Build script for PGFem3D singularity container. Modified from Docker build script by ekissel@indiana.edu
# Maintainer: ckankel@nd.edu, ezkissel@indiana.edu

PREFIX=/

# Installing intel MKL
tar -xf $INTEL_MKL
${INTEL_MKL%.*}/install.sh -s ./mkl_silent.cfg

source /intel/mkl/bin/mklvars.sh intel64

echo " =========================="
echo "| Setting up SuiteSparse...|"
echo " ========================="
tar -xf $SUITESPARSE
sed -i 's/-lmkl_intel_thread/-lmkl_sequential/g' SuiteSparse/SuiteSparse_config/SuiteSparse_config.mk
cd /SuiteSparse
make library
make install INSTALL=$PREFIX/SuiteSparse
cd -

echo " ===================="
echo "| Setting up HYPRE...|"
echo " ===================="
tar -xf $HYPRE
cd ${HYPRE%.tar.gz}/src
./configure --prefix=$PREFIX/hypre --with-MPI CC=mpicc CXX=mpicxx
make 
make install
cd -

echo " ================== "
echo "| Setting up TTL...|"  
echo " ================== "
cd /ttl
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$PREFIX/ttl -DBLA_VENDOR=Intel10_64lp_seq .
make 
make install
cd -

echo " ================== "
echo "| Setting up GCM...|"
echo " ================== "
cd /gcm
./bootstrap
./configure --with-ttl=$PREFIX/ttl \
            --with-mkl=$PREFIX/intel/mkl \
            CXXFLAGS="-O3"
make 
cd -

echo " ================== "
echo "| Setting up Photon...|"
echo " ================== "
tar -xf $PHOTON
cd /${PHOTON%.tar.bz2}
./autogen.sh
./configure --enable-mpi \
            --disable-shmem \
            CC=mpicc CXX=mpicxx CXXFLAGS="-O3"
make 
make install
cd -

echo " ====================== "
echo "| Setting up PGFEM3D...|"
echo " ====================== "
cd /pgfem_3d
./bootstrap
./configure --prefix=$PREFIX/pgfem_3d/deploy/ \
	    --with-hypre=$PREFIX/hypre \
	    --with-ttl=$PREFIX/ttl \
            --with-suitesparse=$PREFIX/SuiteSparse \
            --disable-vtk \
            --enable-photon \
            --with-photon=/usr/local/lib/pkgconfig/photon.pc \
	    --with-cnstvm=$PREFIX/gcm \
	    --enable-tests \
	    --with-tests-nprocs=4 \
	    CC=mpicc CXX=mpicxx CXXFLAGS="-O3 -Wno-uninitialized -Wno-error=format-overflow" \
            PKG_CONFIG_PATH=/usr/local/lib/pkgconfig

make 
make install
cd -
