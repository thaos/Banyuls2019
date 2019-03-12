gcm=$1
rcm=$2
domain=$3
var="tas"

echo "******************************************************************* \n"
echo $gcm $rcm $domain

mkdir -p tmp
mkdir -p out 


nclandsea=$(find CORDEX -name "sftlf_EUR-11_${gcm}*${rcm}*.nc" | head -n 1)
echo $nclandsea
sleep 10
cdo -f nc -setctomiss,0 -gec,1 $nclandsea tmp/landseamask.nc



ncfiles=$(find CORDEX -name "${var}_EUR-11_${gcm}_*_r1i1p1_*${rcm}*.nc")
ncfiles=$(echo $ncfiles | tr " " "\n" | sort | tr "\n" " ")
echo $ncfiles



outlist=""
for f in $ncfiles; do
  echo $f
  basename=${f##*/}
  ncout="tmp/$basename"
  echo ncout: $ncout
  cdo mul ${f} tmp/landseamask.nc tmp/tmp0.nc
  cdo sellonlatbox,${domain} tmp/tmp0.nc tmp/tmp1.nc
  cdo fldmean tmp/tmp1.nc $ncout
  # ${ncout##*/} to get basename
  # cdo setreftime,0000-01-01,00:00 tmp/tmp1.nc tmp/tmp2.nc
  outlist="$outlist $ncout"
done

rm -f tmp/merged.nc
cdo -a mergetime $outlist tmp/merged.nc
cdo seldate,1970-01-01,2100-12-31 -yearmean tmp/merged.nc out/${var}_EUR-11_${gcm}_r1i1p1_${rcm}_dom_${domain}.nc

# for precipitation replace yearmean by yearsum
var="pr"

ncfiles=$(find CORDEX -name "${var}_EUR-11_${gcm}_*_r1i1p1_*${rcm}*.nc")
ncfiles=$(echo $ncfiles | tr " " "\n" | sort | tr "\n" " ")
echo $ncfiles

domaine="-10,30,35,70"
outlist=""
for f in $ncfiles; do
  echo $f
  basename=${f##*/}
  ncout="tmp/$basename"
  echo ncout: $ncout
  cdo mul ${f} tmp/landseamask.nc tmp/tmp0.nc
  cdo sellonlatbox,${domain} tmp/tmp0.nc tmp/tmp1.nc
  cdo fldmean tmp/tmp1.nc $ncout
  # ${ncout##*/} to get basename
  # cdo setreftime,0000-01-01,00:00 tmp/tmp1.nc tmp/tmp2.nc
  outlist="$outlist $ncout"
done

rm -f tmp/merged.nc
cdo -a mergetime $outlist tmp/merged.nc 
cdo seldate,1970-01-01,2100-12-31 -yearsum tmp/merged.nc out/${var}_EUR-11_${gcm}_r1i1p1_${rcm}_dom_${domain}.nc
