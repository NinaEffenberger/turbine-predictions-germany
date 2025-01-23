## Code structure
Most of the folder names are self-explanatory. [exp](./exp) contains all data generating code. `exp/actual_power` contains all code pre-processing actual power generation data. `exp/CMIP6_forecasts_future` generates location-aware and gridded speed and power predictions for 2025 to 2050 using CMIP6. `exp/CMIP6_forecasts_past` generates location-aware and gridded speed and power predictions for 2011 to 2023 with CMIP6 data, the corresponding predictions with ERA5 data are in `exp/ERA5_forecasts`. Code for turbine mapping and hyperparameter optimization is in `exp/others`. 

## Start environment
Run 
```
using Pkg
Pkg.activate("path/to/project")
Pkg.instantiate()
```
to regenerate the Julia environment using `Project.toml` and `Manifest.toml`. 

## Download data
All data is open-source and the corresponding licenses allow for redistribution. You can also download all pre-processed data that was used for the study, except for the actual power generation between 2011 and 2014 on [Zenodo](10.5281/zenodo.14699872). For full transparency and for cases where an analysis of a different region is of interest, we describe how data was downloaded in the following. 

### ERA5
ERA5 data can be downloaded on the [ERA5 website](https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels?tab=download). The data should be stored as one file per year. 

### CMIP6
CMIP6 data can be downloaded using the files in the folder [CMIP6_data_utils](./CMIP6_data_utils). The scripts in `cmip6_download` were generated using the [ESGF metagrid](https://esgf-metagrid.cloud.dkrz.de/search). The files can be stored in [data](./data) See full folder structure for a more detailed description. The files can be pre-processed to only include Germany and to concatenate multiple files. Run `generate_files.sh` first and `extract_subregion.sh` afterwards. The output are smaller files (German region) for all years considered. 

### Wind power data
The wind power data consists of time series data from TSOs and the SMARD database as well as a static wind turbine data set. The code for pre-processing the data can be found in `actual_power/0001_real_power_gen_all.jl`.

The links to all TSO datasets can be found [here](https://open-power-system-data.org/data-sources) under DE clicking on the corresponding links to the individual TSOs Amprion, 50Hertz, Tennet and transnet. 

Actual generation from 2015 onwards can be downloaded from [SMARD] (https://www.smard.de/en/downloadcenter/download-market-data/). 

Turbine locations in Germany are from [Manske and Schmiedt, 2023](https://zenodo.org/records/8188601) and turbines are extracted and matched to a turbine from [windpowerlib](https://windpowerlib.readthedocs.io/en/stable/) in `exp/other/0002_find_turbine.jl`. 