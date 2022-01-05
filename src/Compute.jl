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
        δ_value = multiplier*log(today_close_price / yesterday_close_price)

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
        δ_value = multiplier*((today_close_price - yesterday_close_price) / (yesterday_close_price))

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

function 𝒟(distribution::Type{T}, data::DataFrame, 
    colkey::Symbol)::UnivariateDistribution where T <: ContinuousUnivariateDistribution

    # get the array of data from the data frame -
    data_array = data[!,colkey]

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
