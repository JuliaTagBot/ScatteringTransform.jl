# ScatteringTransform
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://dsweber2.github.io/ScatteringTransform.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://dsweber2.github.io/ScatteringTransform.jl/dev)
[![Build Status](https://travis-ci.com/dsweber2/ScatteringTransform.jl.svg?branch=master)](https://travis-ci.com/dsweber2/ScatteringTransform.jl)
[![Codecov](https://codecov.io/gh/dsweber2/ScatteringTransform.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/dsweber2/ScatteringTransform.jl)
[![Coveralls](https://coveralls.io/repos/github/dsweber2/ScatteringTransform.jl/badge.svg?branch=master)](https://coveralls.io/github/dsweber2/ScatteringTransform.jl?branch=master)

An implementation of the generalized scattering transform in Julia. Documentation in progress.

## Installation
Basic installation: at the moment, this is not an official package. Because of this, to install it, you must first clone it, then make it accessible to your project.

### Dependencies
This uses a modified version of Wavelets.jl that can be found [here](https://github.com/dsweber2/Wavelets.jl), and added via `Pkg.develop("https://github.com/dsweber2/Wavelets.jl.git")`.

### Installation

 In 0.7 onwards, use either `Pkg.add("https://github.com/dsweber2/ScatteringTransform.jl.git")`, `Pkg.develop("https://github.com/dsweber2/ScatteringTransform.jl.git")`, or `] add https://github.com/dsweber2/ScatteringTransform.jl.git` in a REPL. Then from a Repl
```
  (v0.7) pkg> activate .
  (ScatteringTransform) pkg> instantiate
```
either way, make sure you don't have more than a single thread when building by
setting `JULIA_NUM_THREADS = 1` before calling `Pkg.build`.

## Basic Usage

This implementation works strictly on 1 dimensional data and uses Morlet wavelets. If you give it data that has more dimensions, it will transform along the last dimension. There are 2 steps to applying a scattering transform. The first is constructing the transform, done with `layeredTransform(m,example)`. Then you need to actually transform the data; if you are investigating a single example, use `st(f, layers)` to get a `scattered`, a type containing both the intermediate results and the output of each layer. On the other hand, if you're transforming a large set, and only want the outputs, possibly highly subsampled, use `thinSt`.

For more detailed description, see the file [basicUsage.jl](basicUsage.jl)
