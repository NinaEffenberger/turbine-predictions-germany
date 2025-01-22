using Dates
using GeoJSON
#=in windpowerlib find a turbine that is close to the one considered
=#
fc = GeoJSON.read("data/Windenergy_Onshore_V20230420.geojson")
turbines = DataFrame(fc)
df = filter(row -> row.commissioning_date < "2010-12-31", turbines)
df[!, "installed_capacity"] # installed capacity is in kW

turbine_data = CSV.read("data/turbine_data.csv", DataFrame)
filtered_power_curves = turbine_data[turbine_data.has_power_curve.==true, :]
filtered_power_curves[!, "nominal_power"] #is in W

power_differences = []
turbine_names = []
row_indices = []
for i = 1:nrow(turbines)
    target = turbines[i, "installed_capacity"]
    column = filtered_power_curves.nominal_power ./ 1000
    differences = abs.(column .- target)
    sorted_indices = sortperm(differences)
    min_index = sorted_indices[1]
    closest_element = column[min_index]
    row_index = df[min_index, :]
    turbine = filtered_power_curves[min_index, "turbine_type"]
    push!(power_differences, closest_element - target)
    push!(turbine_names, turbine)
    push!(row_indices, min_index)
end

# create one file per year
start_year = 2010
end_year = 2023
date_strings = String[]
for year = start_year:end_year
    date = Date(year, 12, 31)
    push!(date_strings, string(date))
end

"2010-12-31"
date_strings[1]
filter(row -> row.commissioning_date < date_strings[1], turbines)

for i in date_strings
    fc = GeoJSON.read("data/Windenergy_Onshore_V20230420.geojson")
    turbines = DataFrame(fc)
    df = filter(row -> row.commissioning_date < i, turbines)
    turbine_data = CSV.read("data/turbine_data.csv", DataFrame)
    filtered_power_curves = turbine_data[turbine_data.has_power_curve.==true, :]
    filtered_power_curves[!, "nominal_power"] #is in W
    print(size(df))
    power_differences = []
    turbine_names = []
    row_indices = []
    for i = 1:nrow(df)
        target = df[i, "installed_capacity"]
        column = filtered_power_curves.nominal_power ./ 1000
        differences = abs.(column .- target)
        sorted_indices = sortperm(differences)
        min_index = sorted_indices[1]
        closest_element = column[min_index]
        row_index = df[min_index, :]
        turbine = filtered_power_curves[min_index, "turbine_type"]
        push!(power_differences, closest_element - target)
        push!(turbine_names, turbine)
        push!(row_indices, min_index)
    end
    df[!, :turbine_name] = turbine_names
    year = i[1:4]
    CSV.write("data/turbines_in_" * year * ".csv", df)
end
