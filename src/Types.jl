abstract type AbstractBaseCampComputation end

mutable struct LogReturnComputionModel <: AbstractBaseCampComputation

    # data -
    data::DataFrame
    map::Pair{Symbol,Symbol}
    from::Union{Date,Nothing}
    to::Union{Date,Nothing}

    # constructor -
    LogReturnComputionModel() = new()
end

mutable struct LinearReturnComputionModel <: AbstractBaseCampComputation

    # data -
    data::DataFrame
    map::Pair{Symbol,Symbol}
    from::Union{Date,Nothing}
    to::Union{Date,Nothing}

    # constructor -
    LinearReturnComputionModel() = new()
end
