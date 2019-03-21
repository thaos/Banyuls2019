# Scripts for ESGF data access exercices

Spring School Banyuls sur Mer, 2019

Authors: Lola Corre, Soulivanh Thao

### Requirements

ESGF
 - have an account on one of the esgf node (e.g. https://esgf-node.ipsl.upmc.fr/projects/esgf-ipsl/)
 - subscribe to CORDEX Research to have access to CORDEX data.


Softwares
 - bash
 - wget 
 - curl
 - R
 - netCDF4
 - CDO (1.9.3)
 - GDAL
 - ncview (optional)
 
R packages

 - sp
 - rgdal
 - maps
 - maptools
 - ncdf4
 
#### For windows users
EURO-CORDEX data are retrieved from  the ESGF portable using bash scripts and the wget command.

You need to install either Windows Subsystem for Linux (WSL for Windows 10) or a software like Cygwin to do so (c.f. e.g. [stackoverflow](https://stackoverflow.com/questions/15736898/running-a-shell-script-through-cygwin-on-windows)).

You may also need to have a look on how to use CDO with Cygwin ([some instructions here](https://www.isimip.org/protocol/isimip2b-files/cdo-help/)).

### Order of the Scripts
Scripts need to be run in order:
- 0_download_esgf_data.sh is used to retrieved data from ESGF portal.
- 1_CDO_ex1_allrcms.sh is used to prepare the downloaded data using CDO commands.
- 2_CDO_ex2.sh contains the solution of additional CDO exercices.
- 3_read_and_plot_ncdf.R shows how to import the prepared data into R and how to plot them. It uses NetCDF outputs from 1_CDO_ex1_allrcms.sh and 2_CDO_ex2.sh.

#### Remarks:
All the scripts outputs are written in the current directory and all the inputs files are read from the current directory as well.

### 0_download_esgf_data.sh
To download data from the ESGF portal, and open-id identification and password are requirement.

In the 0_download_esgf_data.sh, you need to modified the openid variable with your ESGF opend-id (first line of script).

The script reads your ESGF password form an environemental variable, $ESGF_PWD. Before using the script, you need to export 
this variable. For instance in bash it is done with the following command :

```
export ESGF_PWD="YourPassword"
```
The files to be download are defined with the urls variable.
You can add new files to be downloaded by appending the urls variables with an url used for [the wget ESGF Search RESTful API](https://earthsystemcog.org/projects/cog/esgf_search_restful_api).
