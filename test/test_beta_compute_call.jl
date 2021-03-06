using PQBaseCamp
using DataFrames
using CSV

# compute array -
compute_model_array = Array{LinearReturnComputationModel,1}()

# ticker_array -
ticker_array = [
    "MRNA", "PFE", "JNJ", "SPY", "AAPL"
]

# build up a list of compute objects -
for ticker ∈ ticker_array

    # load up a sample data file -
    path_to_data_file = "$(pwd())/test/data/$(ticker).csv"
    df = CSV.read(path_to_data_file, DataFrame)

    # compute -
    model = LinearReturnComputationModel()
    model.ticker = ticker
    model.data = df
    model.map = :timestamp => :close

    # grab -
    push!(compute_model_array, model)
end

# compute the cov array -
# first: compute the dictionary of returns -
price_retrun_dictionary = Δ(compute_model_array; multiplier = 100.0)
covm = covariance(ticker_array, price_retrun_dictionary)

# compute the β_array -
β_array = β(ticker_array, price_retrun_dictionary)