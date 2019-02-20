gcm="MOHC-HadGEM2-ES"
rcm="RCA4"
var="tas"

ncfiles=$(find CORDEX -name "${var}_EUR-11_${gcm}_*_r1i1p1_*${rcm}*.nc")
echo $ncfiles

domaine="-10,30,35,70"
outlist=""
for f in $ncfiles; do
  echo $f
  basename=${f##*/}
  ncout="tmp/$basename"
  echo ncout: $ncout
  cdo sellonlatbox,${domaine} ${f} tmp/tmp0.nc
  cdo fldmean tmp/tmp0.nc tmp/tmp1.nc
  # ${ncout##*/} to get basename
  cdo yearmean tmp/tmp1.nc $ncout
  outlist="$outlist $ncout"
done

cdo mergetime $outlist tmp/merged.nc  
cdo seldate,1970-01-01,2100-12-31 tmp/merged.nc ${var}_EUR-11_${gcm}_r1i1p1_${rcm}_dom_${domaine}.nc

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
  cdo sellonlatbox,${domaine} ${f} tmp/tmp0.nc
  cdo fldmean tmp/tmp0.nc tmp/tmp1.nc
  # ${ncout##*/} to get basename
  cdo yearsum tmp/tmp1.nc $ncout
  outlist="$outlist $ncout"
done

cdo mergetime $outlist tmp/merged.nc  
cdo seldate,1970-01-01,2100-12-31 tmp/merged.nc ${var}_EUR-11_${gcm}_r1i1p1_${rcm}_dom_${domaine}.nc
