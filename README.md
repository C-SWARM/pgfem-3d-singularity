# PGFem_3D Singularity Container

This repo contains the build scripts necessary in order build a deployable `singularity` image of [PGFem_3D](https://github.com/C-SWARM/pgfem-3d)

### Requirements
  - root access to a machine to build or access to a machine with singularity to pull image
  - Singularity installed as root (tested with 2.5.2)
  - At least 2.3 GB storage to hold resulting container

## Installation

### Singularity-Hub
Through Singularity-Hub, a portable image built from this repository's `Singularity` build specification can be downloaded
anywhere `singularity` is supported. This container will be matched with the latest change to this repository's
`Singularity` file. Note that this container has `PGFem_3D` built with MVAPICH2-2.2. If a different version is needed 
for infiniband support, a custom container must be built following the instructions in [Running with infiniband](#running-with-infiniband).

To pull the container:
```bash
$ singularity pull shub://C-SWARM/pgfem-3d-singularity
$ mv C-SWARM-pgfem-3d-singularity-master-latest.simg pgfem-3d.simg
```
The result from a `singularity pull` will be a container named `C-SWARM-pgfem-3d-singularity-master-latest.simg` due to
Singularity-Hub naming conventions. It may be best to rename the container to something simple. Once the image is pulled,
it can executed to run `PGFem_3D` seen in [Executing the Container](#executing-the-container)

### Building the container
This method requires root access to a machine with `singularity` installed.

Clone this directory.
```bash 
$ git clone https://github.com/C-SWARM/pgfem-3d-singularity.git
$ cd pgfem-3d-singularity/
```
Build the container using the build command as super user / root. This can take 10-20 minutes depending on machine specs.
A faster build may be achieved by increasing the make workers, replacing `make` with `make -j 4` for example.
```console
$ su -
Password:
# cd /path/to/this/repo
# singularity build pgfem3d.simg Singularity
```

A large amount of text will appear on the screen during the build process. Once completed, a container will be created
named `pgfem3d.simg`.

### Executing the Container
Once finished building or pulling, the container can be executed to run PGFem_3D, passing in any necessary parameters.
```bash
$ ./pgfem3d.simg -SS -help
*** Parsing options from: -help ***
 _______    ______   ________                        ______   _______  
/       \  /      \ /        |                      /      \ /       \ 
$$$$$$$  |/$$$$$$  |$$$$$$$$/______   _____  ____  /$$$$$$  |$$$$$$$  |
$$ |__$$ |$$ | _$$/ $$ |__  /      \ /     \/    \ $$ ___$$ |$$ |  $$ |
$$    $$/ $$ |/    |$$    |/$$$$$$  |$$$$$$ $$$$  |  /   $$< $$ |  $$ |
$$$$$$$/  $$ |$$$$ |$$$$$/ $$    $$ |$$ | $$ | $$ | _$$$$$  |$$ |  $$ |
$$ |      $$ \__$$ |$$ |   $$$$$$$$/ $$ | $$ | $$ |/  \__$$ |$$ |__$$ |
$$ |      $$    $$/ $$ |   $$       |$$ | $$ | $$ |$$    $$/ $$    $$/ 
$$/        $$$$$$/  $$/     $$$$$$$/ $$/  $$/  $$/  $$$$$$/  $$$$$$$/  

SS_USAGE: mpirun -np [NP] PGFem3D -SS [options] input output
MS_USAGE: mpirun -np [NP] PGFem3D -MS [network] -macro-np [P] -micro-group-size [S] [macro OPTION_BLK] [micro OPTION_BLK]
OPTION_BLK: -[scale]-start [options] input output -[scale]-end
. . .
```

## Running with infiniband

By using the host's shared libraries it is possible to utilize infiniband. In order to properly communicate, within
the container it is best to build the version of MPI library normally used on the host to communicate over infiband.
In the current singularity container defined by the `Singularity` specification file and the image hosted on
`Singularity-Hub`, `mvapich2-2.2` is built inside and configured with `--disable-wrapper-rpath`. This allows the container's
`libmpi.so` to be swapped to utilize the host's copy. If a targeted cluster requires a different version of MVAPICH or
different implementation of MPI, replace the current download and build of `MVAPICH` with the desired version within the
`Singularity` build file. 
```bash
export MVAPICH=mvapich2-2.2.tar.gz
curl -O http://mvapich.cse.ohio-state.edu/download/mvapich/mv2/$MVAPICH
. . .
tar -xf $MVAPICH
cd ${MVAPICH%.tar.gz}
./configure --prefix=/mvapich --disable-wrapper-rpath
make -j 4 install
export PATH=$PATH:/mvapich/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/mvapich/lib
```
Once the matching version of MPI is built into the container, `pgfem_3d` can be built using the MPI just compiled. In this
repository, it is built within the `build.sh` helper script. While running on the targeted host is necessary to [Swap libraries](#library-swapping)

### Library swapping

Once the container is built and transferred over to a host, a job script should be built with the following to pass host
libraries and paths into the container. If the container and necessary files to run live in a FS space other than the
current user's home space, it will be necessary to pass that along below as well within the `SINGULARITY_BINDPATH` variable.
This is an example of a partial script on [Quartz at LLNL](https://hpc.llnl.gov/hardware/platforms/Quartz):
```bash
module load mvapich2/2.2
module load mkl/2018.0
# Passing dynamic libraries
export SINGULARITYENV_LD_LIBRARY_PATH=$LD_LIBRARY_PATH
# Passing FS paths for host MVAPICH and where the container is stored
export SINGULARITY_BINDPATH="/usr/tce/packages/mvapich2/mvapich2-2.2-gcc-7.1.0/lib,/p/lscratchh/USERNAME"
cd /p/lscratchh/USERNAME/pgfem-3d-examples
./run.sh
```

## Running pgfem-3d-examples

Singularity can utilize the host's native file system, allowing the following commands to be performed outside
the container on the machine targeted to run on. Be sure to transfer the container to the targeted machine in order 
to execute it.

Clone the examples to obtain the source:
```bash
$ git clone https://github.com/C-SWARM/pgfem-3d-examples.git
$ cd pgfem-3d-examples
```
Replace the executable within run.sh with the singularity image.
```bash
$ export PGFEM_SIMG=/path/to/pgfem_3d.simg
$ sed -i 's|/opt/pgfem-3d/bin/PGFem3D|'"${PGFEM_SIMG}"'|' run.sh
```
From here follow the directions supplied within pgfem-3d-examples:
```bash
$ ./local_makeset.pl -np 4
$ ./run.sh
```

## Help
For any technical assistance, please contact:

1.  Cody Kankel [ckankel@nd.edu](mailto:ckankel@nd.edu)
2.  Ezra Kissel [ezkissel@indiana.edu](mailto:ezkissel@indiana.edu)
3.  Kamal K Saha [ksaha@nd.edu](mailto:ksaha@nd.edu)
4.  Luke D'Alessandro [ldalessa@uw.edu](mailto:ldalessa@uw.edu)

