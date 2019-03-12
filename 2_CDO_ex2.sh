gcm="MOHC-HadGEM2-ES"
rcm="RACMO22E"
var="tas"


ncfile="merged.nc" 
outdir="ex2out"
mkdir -p $outdir
ncfile="${outdir}/masked.nc" 

ncfiles=$(find CORDEX -name "${var}_EUR-11_${gcm}_*_r1i1p1_*${rcm}*.nc")
cdo -O mergetime $ncfiles $outdir/merged.nc

sftlf=$(find CORDEX -name "sftlf_EUR-11_${gcm}_historical_*${rcm}*.nc")
cdo -O mul $outdir/merged -setctomiss,0 -gec,1 $sftlf  $ncfile

# moyennes saisonnières sur JJA
seas_x="JJA"
cdo seasmean -selseas,${seas_x} $ncfile  $outdir/meanjja.nc
# min / max
# yearmin, yearmax
cdo yearmean $ncfile  $outdir/meanyear.nc
# clim
cdo timmean -yearmean $ncfile $outdir/clim.nc
# anomalies
cdo seldate,1971-01-01,2000-12-31 $ncfile $outdir/ref_1m.nc
cdo ymonmean $outdir/ref_1m.nc $outdir/ymonmean.nc
cdo ymonsub $ncfile $outdir/ymonmean.nc $outdir/anom_1m.nc
# or with pipe
cdo ymonsub $ncfile -ymonmean $outdir/ref_1m.nc $outdir/anom_1m.nc

