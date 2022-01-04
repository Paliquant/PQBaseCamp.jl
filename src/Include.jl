# setup internal paths -
_PATH_TO_SRC = dirname(pathof(@__MODULE__))

# load external packages that we depend upon -
using DataFrames
using CSV
using Dates

# load my codes -
include(joinpath(_PATH_TO_SRC,"Types.jl"))
include(joinpath(_PATH_TO_SRC,"Base.jl"))
include(joinpath(_PATH_TO_SRC,"Compute.jl"))