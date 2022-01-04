using PQBaseCamp
using DataFrames
using CSV

# make an exponential weight model -
function ew(data::DataFrame, map::Pair{Symbol,Symbol})::Array{Float64,1}

    # initialize -
    ω_array = Array{Float64,1}()
    α = 0.01

    # how many rows do we have?
    (number_of_rows, _) = size(data)
    for row_index ∈ 1:number_of_rows

        value = (1-α)^(row_index - 1)
        push!(ω_array,value)
    end

    # scale - so that we sum to 1 
    T = sum(ω_array)
    return (1/T)*ω_array
end

# load up a sample data file -
path_to_data_file = "$(pwd())/test/data/SPY.csv"
df = CSV.read(path_to_data_file, DataFrame)

# build a computation model -
model = LogReturnComputionModel()
model.data = df
model.map = :timestamp => :close
μ_table = δ(model; weights=ew)
