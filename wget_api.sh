url='http://esgf-node.ipsl.upmc.fr/esg-search/wget?project=CORDEX&domain=EUR-11&driving_model=CNRM-CERFACS-CNRM-CM5&driving_model=ICHEC-EC-EARTH&driving_model=MOHC-HadGEM2-ES&driving_model=MPI-M-MPI-ESM-LR&rcm_name=CCLM4-8-17&rcm_name=RCA4&experiment=historical &experiment=rcp85&time_frequency=mon&variable=pr&variable=tas&download_structure=project,driving_model,rcm_name,experiment,variable'

echo $url

wget -O wget_cordex.sh "$url"
