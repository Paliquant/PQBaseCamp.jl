function Δ(model::LogReturnComputionModel; multiplier::Float64 = 1.0)::DataFrame

    # get stuff from the computational model -
    raw_data = model.data
    from = model.from
    to = model.to
    map = model.map

    # ok, so need to filter the data (if we have a from and to date set)
    data = raw_data
    if (isnothing(to) == false && isnothing(from) == false)

        # get the date key from the map -
        date_key = map.first

        # filter to the specified date range -
        data = filter(date_key => d -> (d >= from && d <= to), raw_data)
    end

    # initialize -
    (number_of_rows, _) = size(data)
    return_table = DataFrame(date = Date[], P₁ = Float64[], P₂ = Float64[], Δ = Float64[], Δ₍μ₎ = Float64[], Z = Float64[])

    # main loop -
    for row_index ∈ 2:number_of_rows

        # grab the date -
        tmp_date = data[row_index, map.first]

        # grab the price data -
        yesterday_close_price = data[row_index-1, map.second]
        today_close_price = data[row_index, map.second]

        # compute the diff -
        δ_value = multiplier * log(today_close_price / yesterday_close_price)

        # push! -
        push!(return_table, (tmp_date, yesterday_close_price, today_close_price, δ_value, 0.0, 0.0))
    end

    # compute the mean -
    μ = mean(return_table[!, :Δ])

    # compute the std -
    σ = std(return_table[!, :Δ])

    # add values to the δ - μ col -
    (number_of_rows, _) = size(return_table)
    for row_index ∈ 1:number_of_rows
        value = return_table[row_index, :Δ] - μ
        return_table[row_index, :Δ₍μ₎] = value
    end

    # add the Z column -
    for row_index ∈ 1:number_of_rows
        value = (1 / σ) * (return_table[row_index, :Δ] - μ)
        return_table[row_index, :Z] = value
    end

    # return -
    return return_table
end

function Δ(model::LinearReturnComputionModel; multiplier::Float64 = 1.0)::DataFrame

    # get stuff from the computational model -
    raw_data = model.data
    from = model.from
    to = model.to
    map = model.map

    # ok, so need to filter the data (if we have a from and to date set)
    data = raw_data
    if (isnothing(to) == false && isnothing(from) == false)

        # get the date key from the map -
        date_key = map.first

        # filter to the specified date range -
        data = filter(date_key => d -> (d >= from && d <= to), raw_data)
    end

    # initialize -
    (number_of_rows, _) = size(data)
    return_table = DataFrame(date = Date[], P₁ = Float64[], P₂ = Float64[], Δ = Float64[], Δ₍μ₎ = Float64[], Z = Float64[])

    # main loop -
    for row_index ∈ 2:number_of_rows

        # grab the date -
        tmp_date = data[row_index, map.first]

        # grab the price data -
        yesterday_close_price = data[row_index-1, map.second]
        today_close_price = data[row_index, map.second]

        # compute the diff -
        δ_value = multiplier * ((today_close_price - yesterday_close_price) / (yesterday_close_price))

        # push! -
        push!(return_table, (tmp_date, yesterday_close_price, today_close_price, δ_value, 0.0, 0.0))
    end

    # compute the mean -
    μ = mean(return_table[!, :Δ])

    # compute the std -
    σ = std(return_table[!, :Δ])

    # add values to the δ - μ col -
    (number_of_rows, _) = size(return_table)
    for row_index ∈ 1:number_of_rows
        value = return_table[row_index, :Δ] - μ
        return_table[row_index, :Δ₍μ₎] = value
    end

    # add the Z column -
    for row_index ∈ 1:number_of_rows
        value = (1 / σ) * (return_table[row_index, :Δ] - μ)
        return_table[row_index, :Z] = value
    end

    # return -
    return return_table
end

function Δ(models::Array{T,1};
    multiplier::Float64 = 1.0)::Dict{String,DataFrame} where {T<:AbstractBaseCampComputation}


    # initialize -
    Δ_dictionary = Dict{String,DataFrame}()

    # compute the returns for each model in the array -
    for model ∈ models
        ticker = model.ticker
        Δ_dictionary[ticker] = Δ(model; multiplier = multiplier)
    end

    # return -
    return Δ_dictionary
end

function 𝒟(distribution::Type{T}, data::DataFrame,
    colkey::Symbol)::UnivariateDistribution where {T<:ContinuousUnivariateDistribution}

    # get the array of data from the data frame -
    data_array = data[!, colkey]

    # do the fit -
    return fit(distribution, data_array)
end

function 𝒫(compare::Function, samples::Array{Float64})::Float64

    # initialize -
    number_of_samples = length(samples)
    tmp_array = BitArray(undef, (number_of_samples, 1))

    # main -
    for sample_index ∈ 1:number_of_samples

        # get the sample price -
        sample_price = samples[sample_index]

        # check: which is larger, sample or target price?
        compare(sample_price) ? tmp_array[sample_index] = 1 : tmp_array[sample_index] = 0
    end

    # sum the tmp_array -
    number_of_larger_values = sum(tmp_array)

    # compute the probability -
    return (number_of_larger_values / number_of_samples)
end

function cov(tickers::Array{String,1}, data::Dict{String,DataFrame}; key::Symbol = :Δ)::Array{Float64,2}

    # build a return matrix -
    number_of_tickers = length(tickers)

    # get the first data table so we can get the number of rows -
    (number_of_rows, _) = size(data[first(tickers)])

    # initialize -
    price_return_array = Array{Float64,2}(undef, number_of_rows, number_of_tickers)

    # populate the price return array -
    for col_index ∈ 1:number_of_tickers

        # get the ticker -
        ticker_symbol = tickers[col_index]

        # get data -
        df = data[ticker_symbol]

        for row_index ∈ 1:number_of_rows
            price_return_array[row_index, col_index] = df[row_index, key]
        end
    end

    # compute the cov array -
    return Statistics.cov(price_return_array)
end

function β(tickers::Array{String,1}, data::Dict{String,DataFrame};
    key::Symbol = :Δ, base::String = "SPY")::Array{Float64,2}

    # initialize -
    number_of_tickers = length(tickers)
    β_array = Array{Float64,1}(undef, number_of_tickers)

    # compute the covariance -
    covm = cov(tickers, data; key = key)

    # what index is the base ticker in the tickers array?
    index_base = indexin(base, tickers)

    # get the variance of the base ticker -
    var_base_ticker = covm(index_base, index_base)

    # compute β -
    for ticker_index ∈ 1:number_of_tickers

        # compute the β_value -
        β_value = covm(ticker_index, index_base) * (1 / var_base_ticker)

        # capture -
        β_array[ticker_index] = β_value
    end

    # return -
    return β_array
end

