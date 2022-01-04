using PQBaseCamp
using DataFrames
using CSV
using Distributions

# load up a sample data file -
path_to_data_file = "$(pwd())/test/data/SPY.csv"
df = CSV.read(path_to_data_file, DataFrame)

# build a computation model -
model = LogReturnComputionModel()
model.data = df
model.map = :timestamp => :close
Δ_table = Δ(model)

# estimate a distribution from this data -
D = 𝒟(Laplace, Δ_table, :Z)