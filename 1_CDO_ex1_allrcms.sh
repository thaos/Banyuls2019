declare -a gcms=(MOHC-HadGEM2-ES MOHC-HadGEM2-ES MPI-M-MPI-ESM-LR CNRM-CERFACS-CNRM-CM5 CNRM-CERFACS-CNRM-CM5)
#declare -a rcms=(RACMO22E RCA4 RCA4) 
declare -a rcms=(RACMO22E CCLM4-8-17 CCLM4-8-17 RACMO22E ALADIN63) 

domains="23.625,27.375,61.625,63.375
7.375,11.125,61.125,62.875
25.675,28.625,52.625,54.375
-3.125,-0.125,52.875,54.625
9.375,12.125,49.375,51.125
-0.375,2.125,45.375,47.125
10.375,12.875,45.625,47.375
23.125,25.875,45.625,47.375
20.625,22.875,38.625,40.375
-8.625,-6.125,41.375,43.125
-4.625,-2.375,37.125,38.875
8.875,10.875,34.875,36.875
-180,180,-90,90"


# get length of an array
arraylength=${#gcms[@]}

for dom in $domains; do
  # use for loop to read all values and indexes
  echo domain: $dom
  for (( i=1; i<${arraylength}+1; i++ ));
  do
    echo $i " / " ${arraylength} " : "
    bash CDO_ex1_onercm.sh ${gcms[$i-1]} ${rcms[$i-1]} $dom
  done
done
