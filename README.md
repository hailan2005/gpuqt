# GPUQT

An efficient implementation of linear scaling quantum transport (LSQT) methods which supports both pure CPU and GPU+CPU computations. This code can be used to obtain charge and spin transport properties of large systems described by a real-space tight-binding Hamiltonian. This is a work in progress. We aim to complete version 1.0 in a few months.

## Related code
There is an independent code from Stephan Roche's group which might be more comprehensive than GPUQT. Here is the link:
https://github.com/proyectoRMP/proyectormp.github.io

## References

The most original paper on this method is:
* [1] S. Roche and D. Mayou, Conductivity of Quasiperiodic Systems: A Numerical Study, Phys. Rev. Lett. 79, 2518 (1997). https://doi.org/10.1103/PhysRevLett.79.2518 

The major reference for the CUDA implementation is 
* [2] Z. Fan, A. Uppstu, T. Siro, and A. Harju, Efficient linear-scaling quantum transport calculations on graphics processing units and applications on electron transport in graphene, Comput. Phys. Commun. 185, 28 (2014). https://doi.org/10.1016/j.cpc.2013.08.009

This code was first published along with the following paper:
* [3] Z. Fan, V. Vierimaa, and Ari Harju, GPUQT: An efficient linear-scaling quantum transport code fully implemented on graphics processing units, Comput. Phys. Commun. 230, 113 (2018). https://doi.org/10.1016/j.cpc.2018.04.013

There is a comprehensive review article discussing the linear scaling quantum transport methods:
* [4] Zheyong Fan, Jose Hugo Garcia, Aron W. Cummings, Jose-Eduardo Barrios, Michel Panhans, Ari Harju, Frank Ortmann, and Stephan Roche, Linear Scaling Quantum Transport Methodologies, submitted to Reviews of Modern Physics, https://arxiv.org/abs/1811.07387

## File organizations

* After downloading and unpacking this code, one can see three directories: `src`, `doc`, and `examples`. 

* The directory `src` contains all the source files (with suffix `.h` or `.cu`) of the main code and two makefiles. The source files are:
    * `main.cu` - the main function
    * `lsqt.h` and `lsqt.cu` - the "driver function"
    * `sigma.h` and `sigma.cu` - functions to obtain the transport properties
    * `model.h`, `model.cu`, `model_general.cu`, and `model_lattice.cu` - class to define the simulation model
    * `anderson.h` and `anderson.cu` - class to add Anderson disorder
    * `charge.h` and `charge.cu` - class to add charged impurities
    * `hamiltonian.h` and `hamiltonian.cu` - class to perform the matrix-related operations
    * `vector.h` and `vector.cu` - class to perform the vector-related operations
    
* The directory `examples` contains some sub-directories and sub-sub-directories, corresponding to different examples.

* There is also a file named `input.txt` in the `examples` directory, which is a "driver input file" (see below).

* The `doc` directory contains the `pdf` and source files for the manual of this code.

## Prerequisites

* To use the CPU version, it only requires a `g++` compiler.
* To use the GPU version, it also requires a CUDA-enabled GPU with compute capability of 3.5 or higher and a `CUDA` toolkit.
* The code has only been tested in linux systems.

## Installing

* Go to `src` and 
    * type `make -f makefile.cpu` to build the CPU version. This will produce an executable called `lsqt_cpu` in the `src` folder.
    * type `make -f makefile.gpu` to build the GPU version. This will produce an executable called `lsqt_gpu` in the `src` folder.

## Running the examples

* Edit the file `examples/input.txt` to include the paths (relative or absolute) of the working directories containing the examples you want to run.

* Go to the main folder where you can see the `src` folder and type one of the following commands:
    * `src/lsqt_gpu examples/input.txt`
    * `src/lsqt_cpu examples/input.txt`
    
* The results will be written into the output files (with suffix `.out`) in the working directories specified in `examples/input.txt`. If you run a simulation multiple times, new data will be appended to the existing output files.

## Analyzing the results

Go to the working directories and run the `MATLAB` scripts we have prepared. After getting familiar with the output files, one can analyze the results using her/his favorite computer language(s). 


## Authors

* Zheyong Fan (Aalto University): Wrote the first working version of this code.

* Ville Vierimaa (Aalto University): Changed the code from the original C style to the current `C++` style and made many other improvements.

* Ari Harju (Aalto University): The supervisor of this project.

## Contact

* Zheyong Fan: brucenju(at)gmail.com; zheyong.fan(at)aalto.fi;

