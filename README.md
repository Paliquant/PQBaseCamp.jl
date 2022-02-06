## Introduction
`PQBaseCamp.jl` is [Julia](https://julialang.org) package that encodes basic methods required
by other [Paliquant](https://www.paliquant.com) packages. 

## Installation and Requirements
`PQBaseCamp.jl` can be installed, updated, or removed using the [Julia package management system](https://docs.julialang.org/en/v1/stdlib/Pkg/). To access the package management interface, open the [Julia REPL](https://docs.julialang.org/en/v1/stdlib/REPL/), and start the package mode by pressing `]`.
While in package mode, to install `PQBaseCamp.jl`, issue the command:

    (@v1.7.x) pkg> add PQBaseCamp

To use `PQBaseCamp.jl` in your projects, issue the command:

    julia> using PQBaseCamp

## Quick start guide
`PQBaseCamp.jl` exports six functions for doing basic computation on the financial data. It is assumed
the data is downloaded from [Polygon.io](https://polygon.io) using the [PQPolygonSDK.jl](https://github.com/Paliquant/PQPolygonSDK.jl) package. 

### Compute log or linear price returns
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

### Fitting probability density functions to price return data
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

The `𝒟(...)` method returns a [Dict](https://docs.julialang.org/en/v1/base/collections/#Dictionaries) holding the distribution models (ticker symbols as keys) where the input argument 
`data` is a [Dict](https://docs.julialang.org/en/v1/base/collections/#Dictionaries) with 
ticker symbols as keys pointing to return [DataFrames](https://dataframes.juliadata.org/stable/). 

### Computing beta
[Beta](https://www.investopedia.com/ask/answers/070615/what-formula-calculating-beta.asp) is a measure of the volatility of an asset or portfolio relative to the overall market. Beta is defined as the covariance between an asset's return and the market return, dived by the variance of the market return:

```julia
β(tickers::Array{String,1}, data::Dict{String,DataFrame};
    key::Symbol = :Δ, base::String = "SPY") --> Array{Float64,1}
```

The `β(...)` function returns an array
of beta values (in the same order as the `tickers` array). The `tickers` array holds a list of ticker symbols, and `data` is a [Dict](https://docs.julialang.org/en/v1/base/collections/#Dictionaries) holding ticker symbols as keys pointing to return [DataFrames](https://dataframes.juliadata.org/stable/). The optional argument `key` of type `Symbol` holds the column name for the return column in the `data` 
[DataFrame](https://dataframes.juliadata.org/stable/), and `base` denotes the ticker symbol for
the market, taken to be [SPY](https://www.google.com/finance/quote/SPY:NYSEARCA?sa=X&ved=2ahUKEwj04c6Oiuv1AhVPmeAKHW-wBG4Q3ecFegQIERAU) by default.

### Covariance
The covariance function is a wrapper around the [cov](https://docs.julialang.org/en/v1/stdlib/Statistics/#Statistics.cov) function of the [Statistics.jl](https://github.com/JuliaLang/Statistics.jl) package in the standard library:

```julia
covariance(tickers::Array{String,1}, data::Dict{String,DataFrame}; 
    key::Symbol = :Δ) --> Array{Float64,2}
```

The `covariance(...)` function returns the [covariance matrix](https://en.wikipedia.org/wiki/Covariance_matrix)
in the same order as the `tickers` array. The `tickers` array holds a list of ticker symbols, and `data` is a [Dict](https://docs.julialang.org/en/v1/base/collections/#Dictionaries) holding ticker symbols as keys pointing to return [DataFrames](https://dataframes.juliadata.org/stable/). The optional argument `key` of type `Symbol` holds the column name for the return data in the `data` 
[DataFrame](https://dataframes.juliadata.org/stable/).

### Sampling
[Paliquant](https://www.paliquant.com) relies heavily on [Monte-Carlo methods](https://en.wikipedia.org/wiki/Monte_Carlo_method). A key component of [Monte-Carlo approaches](https://en.wikipedia.org/wiki/Monte_Carlo_method)
is sampling:

```julia
sample(model::T, number_of_steps::Int64;
    number_of_sample_paths = 100, number_of_strata = 1) --> Array{Float64,2} where {T<:ContinuousUnivariateDistribution}
```

The `sample(...)` function generates a `number_of_steps` by `2 * number_of_sample_paths` array of random draws from the `model`, where `model` is any type of continuous univariate probability density function
encoded in the [Distributions.jl](https://github.com/JuliaStats/Distributions.jl) package. 
The optional argument `number_of_strata` (default: 1) is used for [stratified sampling](https://en.wikipedia.org/wiki/Stratified_sampling); the `number_of_strata` denotes the number of subpopulations to construct. 
The `sample(...)` uses the [antithetic variates method](https://en.wikipedia.org/wiki/Antithetic_variates) for variance reduction when generating samples.


## Disclaimer and Risks
[Paliquant](https://www.paliquant.com) software and `PQBaseCamp.jl` is offered solely for training and  informational purposes. No offer or solicitation to buy or sell securities or securities derivative products of any kind, or any type of investment or trading advice or strategy,  is made, given or in any manner endorsed by [Paliquant](https://www.paliquant.com). 

Trading involves risk. Carefully review your financial situation before investing in securities, futures contracts, options or commodity interests. Past performance, whether actual or indicated by historical tests of strategies, is no guarantee of future performance or success. Trading is generally not appropriate for someone with limited resources, investment or trading experience, or a low-risk tolerance.  Only risk capital that will not be needed for living expenses.

You are fully responsible for any investment or trading decisions you make, and such decisions should be based solely on your evaluation of your financial circumstances, investment or trading objectives, risk tolerance and liquidity needs. 
