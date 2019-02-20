gcm=$1
rcm=$2
domain=$3
var="tas"

ncfiles=$(find CORDEX -name "${var}_EUR-11_${gcm}_*_r1i1p1_*${rcm}*.nc")
echo $ncfiles

outlist=""
for f in $ncfiles; do
  echo $f
  basename=${f##*/}
  ncout="tmp/$basename"
  echo ncout: $ncout
  cdo sellonlatbox,${domain} ${f} tmp/tmp0.nc
  cdo fldmean tmp/tmp0.nc tmp/tmp1.nc
  # ${ncout##*/} to get basename
  # cdo setreftime,0000-01-01,00:00 tmp/tmp1.nc tmp/tmp2.nc
  cdo yearmean tmp/tmp1.nc $ncout
  outlist="$outlist $ncout"
done

rm -f tmp/merged.nc
cdo mergetime $outlist tmp/merged.nc
cdo seldate,1970-01-01,2100-12-31 tmp/merged.nc ${var}_EUR-11_${gcm}_r1i1p1_${rcm}_dom_${domain}.nc

# for precipitation replace yearmean by yearsum
var="pr"

ncfiles=$(find CORDEX -name "${var}_EUR-11_${gcm}_*_r1i1p1_*${rcm}*.nc")
echo $ncfiles

domaine="-10,30,35,70"
outlist=""
for f in $ncfiles; do
  echo $f
  basename=${f##*/}
  ncout="tmp/$basename"
  echo ncout: $ncout
  cdo sellonlatbox,${domain} ${f} tmp/tmp0.nc
  cdo fldmean tmp/tmp0.nc tmp/tmp1.nc
  # ${ncout##*/} to get basename
  # cdo setreftime,0000-01-01,00:00 tmp/tmp1.nc tmp/tmp2.nc
  cdo yearmean tmp/tmp1.nc $ncout
  outlist="$outlist $ncout"
done

rm -f tmp/merged.nc
cdo mergetime $outlist tmp/merged.nc 
cdo seldate,1970-01-01,2100-12-31 tmp/merged.nc ${var}_EUR-11_${gcm}_r1i1p1_${rcm}_dom_${domain}.nc
