# `make-dask`: A GNU Make module to run code over a Dask compute cluster

The included Makefile involves a certain number of macros (`call`-able
variables) and rules in order to set up a Dask cluster as a pre-requisite to
running Make recipes. It does not make your computations Dask-aware -- this
remains the programmer's job. However, it will set up a Dask scheduler and a
set of workers that will divide between each other the Dask-aware computations
run through a Makefile.

## Installation

TBD

## Usage and configuration

TBD

## Example

TBD
