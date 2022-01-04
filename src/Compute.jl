function δ(model::LogReturnComputionModel; 
    weights::Union{Function,Nothing} = nothing)::DataFrame

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
        data = filter(date_key => d->(d>=from && d<=to), raw_data)
    end

    # initialize -
    (number_of_rows, _) = size(data)
    return_table = DataFrame(date = Date[], P₁ = Float64[], P₂ = Float64[], μ = Float64[]);

    # Finally, before we do any computation, if we have a weighting function, compute the weights -
    ω = ones(number_of_rows)
    if (isnothing(weights) == false)
        ω = weights(data, map)
    end

    # main loop -
    for row_index ∈ 2:number_of_rows

        # grab the date -
        tmp_date = data[row_index, map.first]

        # grab the price data -
        yesterday_close_price = ω[row_index-1]*data[row_index-1, map.second]
        today_close_price = ω[row_index]*data[row_index, map.second]

        # compute the diff -
        μ_value = log(today_close_price / yesterday_close_price)

        # push! -
        push!(return_table, (tmp_date, yesterday_close_price, today_close_price, μ_value))
    end

    # return -
    return return_table
end