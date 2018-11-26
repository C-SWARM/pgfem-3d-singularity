# PGFem_3D Singularity Container

This repo contains the build scripts necessary in order build a deployable singularity image of [PGFem_3D](https://github.com/C-SWARM/pgfem-3d)

### Requirements

  - root access to a machine
  - Singularity installed as root (tested with 2.5.2)
  - At least 2.3 GB storage to hold resulting container

## Installation / Creation

Clone this directory.
```bash 
# Note this is pre-release, so the following link will NOT work!
$ git clone https://github.com/C-SWARM/pgfem_3d-singularity.git
$ cd pgfem_3d-singularity/
```
Build the container using the build command as super user / root. This can take 10-20 minutes depending on machine specs.
```console
$ su -
Password:
# cd /path/to/this/repo
# singularity build pgfem3d.simg pgfem3d.build
```
Once finished building, the container can be executed to run PGFem_3D, passing in any necessary parameters.
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
```

## Running pgfem-3d-examples

Singularity can utilize the native machine's file system, allowing the following commands to be performed outside the container
on the machine targeted to run on. Be sure to transfer the container to this machine in order to use it.


Clone the examples to obtain the source:
```bash
$ git clone https://github.com/C-SWARM/pgfem-3d-examples.git
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

## Running with infiniband

By using the host's shared libraries it is possible to utilize infiniband. In order to properly communicate, within the container it is best to build the version of MPI library normally used on the host to communicate over infiband. In the current `pgfem_3d` singularity container, `mvapich2-2.2` is built inside `pgfem3d.build` and configured with `--disable-wrapper-rpath`. This allows the container's `libmpi.so` to be swapped to utilize the host's copy.
```bash
cd ${MVAPICH%.tar.gz}
./configure --prefix=/mvapich --disable-wrapper-rpath
make -j 4 install
```
Once the matching version of MPI is built into the container, `pgfem_3d` can be built using the MPI just compiled. In this repo, it is built within the `build.sh` helper script.

### Library swapping

Once the container is built and transferred over to a host, a job script should be built with the following to pass host libraries and paths into the container. If the container and necessary files to run live in a FS space other than the current user's home space, it will be necessary to pass that along below as well within the `SINGULARITY_BINDPATH` variable. This is an example of a partial script on [Quartz at LLNL](https://hpc.llnl.gov/hardware/platforms/Quartz):
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

## Help
For any technical assistance, please contact:

1.  Cody Kankel [ckankel@nd.edu](mailto:ckankel@nd.edu)
2.  Ezra Kissel [ezkissel@indiana.edu](mailto:ezkissel@indiana.edu)
3.  Kamal K Saha [ksaha@nd.edu](mailto:ksaha@nd.edu)
4.  Luke D'Alessandro [ldalessa@uw.edu](mailto:ldalessa@uw.edu)

