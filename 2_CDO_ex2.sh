gcm="MOHC-HadGEM2-ES"
rcm="RCA4"
var="tas"

ncfile="merged.nc" 

ncfiles=$(find CORDEX -name "${var}_EUR-11_${gcm}_*_r1i1p1_*${rcm}*.nc")
cdo mergetime $ncfiles merged.nc

# moyennes saisonnières sur JJA
seas_x="JJA"
cdo seasmean -selseas,${seas_x} $ncfile  meanjja.nc
# min / max
# yearmin, yearmax
cdo yearmean $ncfile  meanyear.nc
# clim
cdo timmean -yearmean $ncfile clim.nc
# anomalies
cdo seldate,1971-01-01,2000-12-31 $ncfile ref_1m.nc
cdo ymonmean ref_1m.nc ymonmean.nc
cdo ymonsub $ncfile monmean.nc anom_1m.nc
cdo ymonsub $ncfile -ymonmean ref_1m.nc anom_1m.nc

