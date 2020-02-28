
# PGFem_3D Singularity Container

This repository contains the build scripts necessary in order build a deployable `singularity` image of [PGFem_3D](https://github.com/C-SWARM/pgfem-3d)

### Requirements
  - Access to a machine with singularity to pull image _or_ root access to a machine to build custom image
  - Singularity installed as root (tested with 3.5.2)
  - At least 2.3 GB storage to hold resulting container

## Obtain the Container

### Option 1: Use prebuilt container
Through Singularity-Hub, a portable image built from this repository's `Singularity` build specification can be downloaded
anywhere `singularity` is supported. This container will be matched with the latest change to this repository's
`Singularity` file. Note that this container has `PGFem_3D` built with MVAPICH2-2.2. If a different version is needed 
for infiniband support, a custom container must be built following the instructions in [Using infiniband](#using-infiniband).

To pull the container:
```bash
$ singularity pull shub://C-SWARM/pgfem-3d-singularity
$ mv C-SWARM-pgfem-3d-singularity-master-latest.simg pgfem-3d.simg
```
The result from a `singularity pull` will be a container named `C-SWARM-pgfem-3d-singularity-master-latest.simg` due to
Singularity-Hub naming conventions. It may be best to rename the container to something simple. 

Once the image is pulled, it can executed to run `PGFem_3D` seen in [Executing the Container](#executing-the-container). 
If an MPI implementation other than `MVAPICH2-2.2` is desired, it is best to build a custom container with the desired MPI. Instructions for building a container are below.


### Option 2: Build the container on own machine
This method requires root access to a machine with `singularity` installed. If `mvapich2-2.2` is satisfactory, it is recommended to 
use the prebuilt image using the instructions above as building a container takes time and space. The following instructions are for
building your own container when the `singularity-hub` image will not suffice.

Clone this directory.
```bash 
$ git clone https://github.com/C-SWARM/pgfem-3d-singularity.git
$ cd pgfem-3d-singularity/
```
Make any changes necessary to the `Singularity` build file or the `build.sh` file where each software component will be compiled. 
Build the container using the `build` command as super user / root. This can take 10-20 minutes depending on machine specs.
A faster build may be achieved by increasing the make workers, replacing `make` with `make -j 4` for example.
```console
$ su -
Password:
# cd /path/to/this/repo
# singularity build pgfem3d.simg Singularity
```

A large amount of text will appear on the screen during the build process. Once completed, a container will be created
named `pgfem3d.simg`.

## Using infiniband

By using the host's shared libraries it is possible to utilize infiniband. In order to properly communicate, within
the container it is best to build the version of MPI library normally used on the host to communicate over infiniband.
In the current singularity container defined by the `Singularity` specification file and the hosted on
`Singularity-Hub`, `mvapich2-2.2` is built and configured with `--disable-wrapper-rpath`. This allows the container's
`libmpi.so` to be swapped to utilize the host's library. If a targeted cluster requires a different version of MVAPICH 
or a different implementation of MPI, replace the current download and build of `MVAPICH` 
with the desired version within the `Singularity` build file. 
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
Once the matching version of MPI is built into the container, `pgfem_3d` should be compiled with this version. `pgfem_3d` is 
built within the `build.sh` helper script. The container can then be built, instrcutions can be found above at [Building the container on own machine](#option-2:-build-the-container-on-own-machine) 

While running on the targeted host, it is necessary to [Swap libraries](#library-swapping) in order to properly utilize infiniband.

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

## Executing the Container
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

If running on an HPC system, it is best to use `mpirun` or an equivalent _outside_ the container. This would require 
the proper module or software in place, such as `module load mvapich2/2.2` for example. If you are intending to 
run using infiniband technologies, see [Using Infiniband](#using-infiniband) above.


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
This will create 2 files within the pgfem-3d-examples directory: `parview_displacement_y.pvsm` and `parview_displacement_z.pvsm`. 
These files can be opened using `ParaView` outside of the container and examined by the following:

1. Click `File -> Load State -> `, select either parview_displacement_y.pvsm or parview_displacement_z.pvsm and click `OK`
2. In the next window, browse to: `out -> box_4 -> VTK -> box_../pvtu` and click `OK`
3. Press the play button towards the top middle of the screen.

## Help
For any technical assistance, please contact:

1.  Cody Kankel [ckankel@nd.edu](mailto:ckankel@nd.edu)
2.  Ezra Kissel [ezkissel@indiana.edu](mailto:ezkissel@indiana.edu)
3.  Kamal K Saha [ksaha@nd.edu](mailto:ksaha@nd.edu)
4.  Luke D'Alessandro [ldalessa@uw.edu](mailto:ldalessa@uw.edu)

