abstract type AbstractBaseCampComputation end

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

mutable struct LinearReturnComputationModel <: AbstractBaseCampComputation

    # data -
    ticker::String
    data::DataFrame
    map::Pair{Symbol,Symbol}
    from::Union{Date,Nothing}
    to::Union{Date,Nothing}

    # constructor -
    LinearReturnComputationModel() = new()
end
