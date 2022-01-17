## Introduction
`PQBaseCamp.jl` is [Julia](https://julialang.org) package that encodes some basic methods required
by other [Paliquant](https://www.paliquant.com) packages. 

## Installation and Requirements
`PQBaseCamp.jl` can be installed, updated, or removed using the [Julia package management system](https://docs.julialang.org/en/v1/stdlib/Pkg/). To access the package management interface, open the [Julia REPL](https://docs.julialang.org/en/v1/stdlib/REPL/), and start the package mode by pressing `]`.
While in package mode, to install `PQBaseCamp.jl`, issue the command:

    (@v1.7.x) pkg> add PQBaseCamp

To use `PQBaseCamp.jl` in your projects, issue the command:

    julia> using PQBaseCamp

## Quick start guide
`PQBaseCamp.jl` exports six functions for doing some basic computation on the financial data from [Polygon.io](https://polygon.io).

#### Compute log or linear price returns
The `Δ` function (and its associated methods) is used to compute either the log or simple (linear) return from price data encoded in a [DataFrame](https://dataframes.juliadata.org/stable/):


```julia
Δ(model::LogReturnComputationModel; multiplier::Float64 = 1.0) --> DataFrame
```

or

```julia
Δ(model::LinearReturnComputationModel; multiplier::Float64 = 1.0) --> DataFrame
```

where `LogReturnComputationModel` or `LogReturnComputationModel` model instances (both of which can the same fields) can be constructed using the default constructor:

```julia
mutable struct LogReturnComputationModel <: AbstractBaseCampComputation

    # data -
    ticker::String
    data::DataFrame
    map::Pair{Symbol,Symbol}
    from::Union{Date,Nothing}
    to::Union{Date,Nothing}

    # constructor -
    LogReturnComputationModel() = new()
end
```

#### Fitting probability density functions to price return data
Sometimes we may want to fit a distribution to historical price returns e.g., when constructing random
walk models for a particular asset or basket of assets. To facilitate this, `PQBaseCamp.jl`  encodes the
`𝒟` function(s):

```julia
𝒟(distribution::Type{T}, data::DataFrame; 
    colkey::Symbol = :Δ) --> UnivariateDistribution where {T<:ContinuousUnivariateDistribution}
```

where [ContinuousUnivariateDistribution](https://juliastats.org/Distributions.jl/stable/univariate/#Continuous-Distributions) is any type of continuous univariate probability density function
encoded in the [Distributions.jl](https://github.com/JuliaStats/Distributions.jl) package.
The optional `colkey` parameter holds the symbol of the column in the `data` [DataFrame](https://dataframes.juliadata.org/stable/) corresponding to the log or simple return values.

In cases where we have many assets that we are interested in, we export a broadcast version of the 
`𝒟` function:

```julia
𝒟(distribution::Type{T}, data::Dict{String, DataFrame}; 
    colkey::Symbol = :Δ) --> Dict{String, T} where {T<:ContinuousUnivariateDistribution}
```

where `data` is a [Dict](https://docs.julialang.org/en/v1/base/collections/#Dictionaries) with 
ticker symbols as keys pointing to return DataFrames. This method returns a [Dict](https://docs.julialang.org/en/v1/base/collections/#Dictionaries) holding the distribution models (ticker symbols as keys).


## Disclaimer and Risks
[Paliquant](https://www.paliquant.com) software and `PQBaseCamp.jl` is offered solely for training and  informational purposes. No offer or solicitation to buy or sell securities or securities derivative products of any kind, or any type of investment or trading advice or strategy,  is made, given or in any manner endorsed by [Paliquant](https://www.paliquant.com). 

Trading involves risk. Carefully review your financial situation before investing in securities, futures contracts, options or commodity interests. Past performance, whether actual or indicated by historical tests of strategies, is no guarantee of future performance or success. Trading is generally not appropriate for someone with limited resources, investment or trading experience, or a low-risk tolerance.  Only risk capital that will not be needed for living expenses.

You are fully responsible for any investment or trading decisions you make, and such decisions should be based solely on your evaluation of your financial circumstances, investment or trading objectives, risk tolerance and liquidity needs. 
