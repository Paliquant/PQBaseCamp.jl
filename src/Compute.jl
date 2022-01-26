function Δ(model::LogReturnComputationModel; multiplier::Float64 = 1.0)::DataFrame

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

function Δ(model::LinearReturnComputationModel; multiplier::Float64 = 1.0)::DataFrame

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

function 𝒟(distribution::Type{T}, ticker_symbol_array::Array{String,1}, data::Dict{String, DataFrame}; 
    colkey::Symbol = :Δ)::ContinuousMultivariateDistribution where {T <: ContinuousMultivariateDistribution}

    # how many keys and rows do we have?
    number_of_ticker_symbols = length(ticker_symbol_array)
    number_of_rows = length(data[first(ticker_symbol_array)][!,colkey])

    # initialize -
    tmp_array = Array{Float64,2}(undef, number_of_rows, number_of_ticker_symbols)

    # build the data array -
    for (ticker_index, ticker_symbol) ∈ enumerate(ticker_symbol_array)
        
        # grab the data for this ticker -
        tmp_data_col = data[ticker_symbol][!,colkey]

        # copy into the tmp array -
        for row_index ∈ 1:number_of_rows
            tmp_array[row_index, ticker_index] = tmp_data_col[row_index]
        end
    end

    # fit the distribution -
    return fit(distribution, transpose(tmp_array))
end

function 𝒟(distribution::Type{T}, data::DataFrame; 
    colkey::Symbol = :Δ)::UnivariateDistribution where {T<:ContinuousUnivariateDistribution}

    # get the array of data from the data frame -
    data_array = data[!, colkey]

    # do the fit -
    return fit(distribution, data_array)
end

function 𝒟(distribution::Type{T}, data::DataFrame, weights::Union{Nothing,Array{Float64,1}};
    colkey::Symbol = :Δ)::UnivariateDistribution where {T<:ContinuousUnivariateDistribution}

    # get the array of data from the data frame -
    data_array = data[!, colkey]

    # check: do we have a weight array?
    if (isnothing(weights) == false)
        
        # do the fit w/weights -
        return fit(distribution, data_array, weights)
    else
         # do the fit w/o weights -
        return fit(distribution, data_array)
    end
end

function 𝒟(distribution::Type{T}, data::Dict{String, DataFrame}; 
    colkey::Symbol = :Δ, weights::Union{Nothing, Dict{String, Union{Nothing,Array{Float64,1}}}} = nothing)::Dict{String, T} where {T<:ContinuousUnivariateDistribution}

    # initialize -
    distribution_dictionary = Dict{String, T}()

    # call the single 𝒟 -
    for (key,value) ∈ data
        
        # get the array of data from the data frame -
        data_array = value[!, colkey]

        # check: do we have weights?
        d = nothing
        if (isnothing(weights) == false && 
            isnothing(weights[key]) == false)

            # we have a weights -
            w = weights[key]

            # fit -
            d = fit(distribution, data_array, w);
        else
            # fit a distribution -
            d = fit(distribution, data_array);
        end
    
        # capture -
        distribution_dictionary[key] = d;
    end
    
    # return data -
    return distribution_dictionary
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

function covariance(tickers::Array{String,1}, data::Dict{String,DataFrame}; 
    key::Symbol = :Δ)::Array{Float64,2}

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
    key::Symbol = :Δ, base::String = "SPY")::Array{Float64,1}

    # initialize -
    number_of_tickers = length(tickers)
    β_array = Array{Float64,1}(undef, number_of_tickers)

    # get the return data for the base -
    base_return_array = data[base][!,key]
    var_base = var(base_return_array)

    # compute β -
    for ticker_index ∈ 1:number_of_tickers

        # what ticker?
        ticker_value = tickers[ticker_index]
        return_array_ticker = data[ticker_value][!,key]

        # compute the β_value -
        β_value = cov(return_array_ticker, base_return_array) * (1 / var_base)

        # capture -
        β_array[ticker_index] = β_value
    end

    # return -
    return β_array
end

function sample(model::T, number_of_steps::Int64;
    number_of_sample_paths = 100, number_of_strata = 1)::Array{Float64,2} where {T<:ContinuousUnivariateDistribution} 

    # initialize -
    number_of_steps = number_of_steps + 1
    sample_return_data = Array{Array{Float64,1},1}(undef, number_of_steps)
	
	# Let's use stratefied sampling to generate the return samples -
    for time_step_index ∈ 1:number_of_steps

		tmp_vector = Array{Float64,1}()
                
        # sample the strata ...
        for strata_index ∈ 1:number_of_strata
            
            # compute a number_of_sample_paths draws from tis strata?
            for _ ∈ 1:number_of_sample_paths
                
                # compute V -
                V₁ = (strata_index - 1)/number_of_strata + rand()/number_of_strata
                V₂ = (strata_index - 1)/number_of_strata + (1-rand())/number_of_strata

                # compute the quantile for this V -
                q₁ = quantile(model, V₁)
                q₂ = quantile(model, V₂)

                # grab this value -
                push!(tmp_vector, q₁)
                push!(tmp_vector, q₂)
            end
        end
		
        sample_return_data[time_step_index] = tmp_vector
    end

    # crunch the data together -
    sample_return_array = transpose(hcat(sample_return_data...))

    # return -
    return sample_return_array
end

function sample(models::Dict{String,T}, number_of_steps::Int64; 
    number_of_sample_paths = 100, number_of_strata = 1)::Dict{String,Array{Float64,2}} where {T<:ContinuousUnivariateDistribution} 

    # initialize -
    sample_dictionary = Dict{String,Array{Float64,2}}()

    # compute -
    for (ticker_symbol, model) ∈ models
        
        # sample this model -
        tmp_array = sample(model, number_of_steps; 
            number_of_sample_paths = number_of_sample_paths, number_of_strata = number_of_strata)

        # store the samples -
        sample_dictionary[ticker_symbol] = tmp_array
    end

    # return -
    return sample_dictionary
end