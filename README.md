# PGFem_3D Singularity Container

This repo contains the build scripts necessary in order build a deployable singularity image of [PGFem_3D](https://github.com/C-SWARM/pgfem-3d)

### Requirements

  - root access to a machine
  - Singularity installed as root (tested with 2.5.2)
  - At least 2.3 GB storage to hold resulting container

## Installation / Creation

Clone this directory.
```bash $ git clone https://github.com/C-SWARM/pgfem_3d-singularity.git
$ cd pgfem_3d-singularity/
```
Build the container using the build command as super user / root. This can take 10-20 minutes depending on machine specs.
```console
$ su
Password:
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

Singularity can utilize the native machine's file system, allowing the following commands to be performed outside the container.


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

### Help
For any technical assistance, please contact:

1.  Cody Kankel [ckankel@nd.edu](mailto:ckankel@nd.edu)
2.  Ezra Kissel [ezkissel@indiana.edu](mailto:ezkissel@indiana.edu)
3.  Kamal K Saha [ksaha@nd.edu](mailto:ksaha@nd.edu)
4.  Luke D'Alessandro [ldalessa@uw.edu](mailto:ldalessa@uw.edu)

