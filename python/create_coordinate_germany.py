import geopandas
import matplotlib.pyplot as plt
import pandas as pd
from shapely.geometry import Point
import xarray as xr

nc = xr.open_dataset("data/ERA5/germany_wind_2011.nc")
nc["time"][:]
lons = nc["longitude"][:]
lats = nc["latitude"][:]

lons_germany = []
lons_index = []
lats_germany = []
lats_index = []
world = geopandas.read_file(geopandas.datasets.get_path("naturalearth_lowres"))
Germany = world[world.name == "Germany"]


for i in range(len(lons)):
    for j in range(len(lats)):
        if Germany.contains(Point(lons[i], lats[j])).item():
            lons_germany.append(lons[i])
            lons_index.append(i)
            lats_germany.append(lats[j])
            lats_index.append(j)
        j += 1
    i+=1

lons_germany = [i.item() for i in lons_germany]
lats_germany = [i.item() for i in lats_germany]

data = {
    'lons': lons_germany,
    'lats': lats_germany,
    'lons_index': lons_index, 
    'lats_index':lats_index
}
df = pd.DataFrame(data)
df.to_csv('data/coordinates/era5.csv', index=False)


df_past = pd.DataFrame({"Latitude": lats_germany, "Longitude": lons_germany})
gdf = geopandas.GeoDataFrame(
    df_past, geometry=geopandas.points_from_xy(df_past.Longitude, df_past.Latitude)
)
fig, ax = plt.subplots(1, 1, figsize=(10, 5), constrained_layout=True)

Germany.plot(ax=ax)
gdf.plot(ax=ax, color="red", markersize=0.3)
#plt.show()

nc = xr.open_dataset("data/generated_data/MPI/uas_r3/outfile_46.66667175292969_55.833335876464844_5.0_15.416666984558105.nc")
nc["time"][:]
lons = nc["lon"][:]
lats = nc["lat"][:]

lons_germany = []
lons_index = []
lats_germany = []
lats_index = []
world = geopandas.read_file(geopandas.datasets.get_path("naturalearth_lowres"))
Germany = world[world.name == "Germany"]


for i in range(len(lons)):
    for j in range(len(lats)):
        if Germany.contains(Point(lons[i], lats[j])).item():
            lons_germany.append(lons[i])
            lons_index.append(i)
            lats_germany.append(lats[j])
            lats_index.append(j)
        j += 1
    i+=1

lons_germany = [i.item() for i in lons_germany]
lats_germany = [i.item() for i in lats_germany]

data = {
    'lons': lons_germany,
    'lats': lats_germany,
    'lons_index': lons_index, 
    'lats_index':lats_index
}
df = pd.DataFrame(data)
df.to_csv('data/coordinates/mpi.csv', index=False)