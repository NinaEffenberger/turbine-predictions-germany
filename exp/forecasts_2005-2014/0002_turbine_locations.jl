using GeoJSON, DataFrames
using GeoMakie, CairoMakie

fc = GeoJSON.read("data/Windenergy_Onshore_V20230420.geojson")
df = DataFrame(fc)
filtered_df = filter(row -> row.commissioning_date < "2010-12-31", df)

print("tes")
latitudes = df.LAT
longitudes = df.LON

fig = Figure()
ax = GeoAxis(fig[1,1], lonlims = (5, 16), latlims = (47, 56))
GeoMakie.scatter!(longitudes, latitudes; color = "black")
fig

