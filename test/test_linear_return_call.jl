using PQBaseCamp
using DataFrames
using CSV

# make an exponential weight model -
function ew(data::DataFrame, map::Pair{Symbol,Symbol})::Array{Float64,1}

    # initialize -
    ω_array = Array{Float64,1}()
    α = 0.05

    # how many rows do we have?
    (number_of_rows, _) = size(data)
    for row_index ∈ 1:number_of_rows

        value = (1 - α)^(row_index - 1)
        push!(ω_array, value)
    end

    # scale - so that we sum to 1 
    T = sum(ω_array)
    return reverse((1 / T) * ω_array)
end

# load up a sample data file -
path_to_data_file = "$(pwd())/test/data/SPY.csv"
df = CSV.read(path_to_data_file, DataFrame)

# what is the w?
ω_array = ew(df, :timestamp => :close)

# build a computation model -
model = LinearReturnComputionModel()
model.ticker = "SPY"
model.data = df
model.map = :timestamp => :close
Δ_table = Δ(model)
