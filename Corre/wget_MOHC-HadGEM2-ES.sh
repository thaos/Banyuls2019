openid=https://esgf-node.ipsl.upmc.fr/esgf-idp/openid/sthao

url='https://esg-dn1.nsc.liu.se/esg-search/wget/?distrib=false&dataset_id=cordex.output.EUR-11.SMHI.MOHC-HadGEM2-ES.rcp85.r1i1p1.RCA4.v1.mon.tas.v20131026|esg-dn1.nsc.liu.se&dataset_id=cordex.output.EUR-11.SMHI.MOHC-HadGEM2-ES.rcp85.r1i1p1.RCA4.v1.mon.pr.v20131026|esg-dn1.nsc.liu.se&dataset_id=cordex.output.EUR-11.SMHI.MOHC-HadGEM2-ES.historical.r1i1p1.RCA4.v1.mon.tas.v20131026|esg-dn1.nsc.liu.se&dataset_id=cordex.output.EUR-11.SMHI.MOHC-HadGEM2-ES.historical.r1i1p1.RCA4.v1.mon.pr.v20131026|esg-dn1.nsc.liu.se&download_structure=project,experiment,driving_model,rcm_name,variable'

curl -s $url > wget_tmp.sh
chmod +x wget_tmp.sh
echo $ESGF_PWD | ./wget_tmp.sh -H -o $openid

mkdir CORDEX/historical/MOHC-HadGEM2-ES/RCA4
find CORDEX/historical/MOHC-HadGEM2-ES -maxdepth 1 \( -name "tas" -o -name "pr" \) -exec cp -rlf {} CORDEX/historical/MOHC-HadGEM2-ES/RCA4 \;
find CORDEX/historical/MOHC-HadGEM2-ES -maxdepth 1 \( -name "tas" -o -name "pr" \) -exec rm -r {} \;
find CORDEX/rcp85/MOHC-HadGEM2-ES -maxdepth 1 \( -name "tas" -o -name "pr" \) -exec cp -rlf {} CORDEX/rcp85/MOHC-HadGEM2-ES/RCA4 \;
find CORDEX/rcp85/MOHC-HadGEM2-ES -maxdepth 1 \( -name "tas" -o -name "pr" \) -exec rm -r {} \;

urls='http://esgf-data.dkrz.de/esg-search/wget/?distrib=false&dataset_id=cordex.output.EUR-11.KNMI.MOHC-HadGEM2-ES.rcp85.r1i1p1.RACMO22E.v2.mon.pr.v20160705|esgf1.dkrz.de&dataset_id=cordex.output.EUR-11.KNMI.MOHC-HadGEM2-ES.rcp85.r1i1p1.RACMO22E.v2.mon.tas.v20160705|esgf1.dkrz.de&dataset_id=cordex.output.EUR-11.KNMI.MOHC-HadGEM2-ES.historical.r1i1p1.RACMO22E.v2.mon.tas.v20160620|esgf1.dkrz.de&dataset_id=cordex.output.EUR-11.KNMI.MOHC-HadGEM2-ES.historical.r1i1p1.RACMO22E.v2.mon.pr.v20160620|esgf1.dkrz.de&download_structure=project,experiment,driving_model,rcm_name,variable 
https://esg-dn1.nsc.liu.se/esg-search/wget/?distrib=false&dataset_id=cordex.output.EUR-11.SMHI.MPI-M-MPI-ESM-LR.rcp85.r1i1p1.RCA4.v1a.mon.tas.v20160803|esg-dn1.nsc.liu.se&dataset_id=cordex.output.EUR-11.SMHI.MPI-M-MPI-ESM-LR.rcp85.r1i1p1.RCA4.v1a.mon.pr.v20160803|esg-dn1.nsc.liu.se&dataset_id=cordex.output.EUR-11.SMHI.MPI-M-MPI-ESM-LR.historical.r1i1p1.RCA4.v1a.mon.tas.v20160803|esg-dn1.nsc.liu.se&dataset_id=cordex.output.EUR-11.SMHI.MPI-M-MPI-ESM-LR.historical.r1i1p1.RCA4.v1a.mon.pr.v20160803|esg-dn1.nsc.liu.se&download_structure=project,experiment,driving_model,rcm_name,variable'

for url in $urls; do
  echo url: $url
  curl -s $url > wget_tmp.sh
  chmod +x wget_tmp.sh
  echo $ESGF_PWD | ./wget_tmp.sh -H -o $openid
done
        