Pruner - A simple & flexible bioinformatics pipeline
====================================================

[![Circle CI](https://circleci.com/gh/wilzbach/read-prunner.svg?style=svg)](https://circleci.com/gh/wilzbach/read-prunner)

Requirements
------------

Typical Unix-like environment with basic development tools - all other dependencies
will be fetched automatically.

- `curl`
- `gzip`
- `gcc`
- GNU `make`

These tools should be part of every Linux distribution.

Ideas
-----

- automatic dependency injection with Makefile rules, e.g. the dependency
  BWA is only downloaded & compiled if needed
- fully automated installation of required tools from their source
- if possible, wildcard patterns instead of rules (e.g. <file>.bwt runs bwt)
- make will generate a dependency chain for our data and regenerate outdated files
- be able to run the newest, latest software on any machine
- use versioning for all dependencies to all reproducibility
- use make -j8 (will automatically parallelize wherever possible)

Reasons for building from source
--------------------------------

- we must be able to run the newest software on old clusters, hence everything
  needs to be built from scratch
- some software licenses don't allow binary releases (GATK)
- we need to be able to inspect & modify the source code
- we want to _understand_ every bit of out pipeline
- if something doesn't build, it's outdated anyhows

Dependencies in the pipeline
----------------------------

Dependencies are automatically generated, e.g.

- bwa -> bwt files
- mason_variator needs fai
- GATK needs fai and dict

Directory structure:
-------------------

- `build`: all required build tools and source code of required programs
- `data`: all experimental results
- `debug`: temporary folder that is used to print some debug information for tests
- `perm`: permanent data that shouldn't be deleted
- `progs`: all required executables of the pipeline
- `src`: this pipeline's source code

Popular make targets:
--------------------

- `make all`: runs the entire pipeline
- `make test`: runs D unittests

Pick out any intermediate file in the pipeline and run `make <file>` to generate
it

Notes
-----

- due to limitations in the Makefile the working directory must be the directory
  of this Makefile
- the folder names are coded statically on purpose

See Also
--------

- [BAM Reader performance test](https://github.com/wilzbach/bam-perf-test)
