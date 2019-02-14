import sys
climaf_folder = '/home/sthao/2_Codes/Thao/CLIMAF/climaf'
climaf_env_folder = '/home/sthao/miniconda3/envs/climaf/lib/python2.7/site-packages'

def add_folder_in_path(folder):
    if folder not in sys.path:
        sys.path.append(folder)
        
#add_folder_in_path(climaf_folder)
#add_folder_in_path(climaf_env_folder)

from climaf.api import *
clog('debug') # min verbosity = critical < warning < info < debug = max verbosity
pattern = '/home/sthao/2_Codes/Thao/Banyuls2019/${project}/${gcm}/${rcm}/${experiment}/${variable}/${variable}_EUR-11_${gcm}_${experiment}_*${rcm}*_${frequency}_${PERIOD}.nc'
cproject('CORDEX', 'gcm', 'rcm', 'experiment', 'frequency', separator='%')
dataloc(project='CORDEX', url=pattern)
cfreqs('CORDEX',{'monthly':'mon' , 'daily':'day' })
test = ds(project = 'CORDEX',
          variable = 'tas',
          experiment = 'rcp85',
          gcm = 'MPI-M-MPI-ESM-LR',
          rcm = 'RCA4',
          frequency = 'monthly',
          period='2001-2050')
summary(test)
test.explore('choices')
ok_test = test.explore('resolve')
ok_test.kvp
# ncdump(test)
#implot(test)

cproject('CORDEX_extent', 'gcm', 'rcm', 'experiment', 'experiment_extent', 'frequency', separator='%')
pattern_hist = '/home/sthao/2_Codes/Thao/Banyuls2019/CORDEX/${gcm}/${rcm}/${experiment}/${variable}/${variable}_EUR-11_${gcm}_${experiment}_*${rcm}*_${frequency}_${PERIOD}.nc'
pattern_rcp = '/home/sthao/2_Codes/Thao/Banyuls2019/CORDEX/${gcm}/${rcm}/${experiment_extent}/${variable}/${variable}_EUR-11_${gcm}_${experiment_extent}_*${rcm}*_${frequency}_${PERIOD}.nc'
dataloc(project='CORDEX_extent', url=pattern_hist)
dataloc(project='CORDEX_extent', url=pattern_rcp)
cdef('experiment'  , 'historical'   , project='CORDEX_extent')
cdef('experiment_extent'  , 'rcp85'   , project='CORDEX_extent')
cdef('frequency'   , 'mon'            , project='CORDEX_extent')



test = ds(project='CORDEX_extent', period='1990-2050', variable='tas', gcm = 'MPI-M-MPI-ESM-LR', rcm = 'RCA4')
summary(test)

test_llbox = llbox(test, lonmin=-80, lonmax=40, latmin=20, latmax=80)

# -- And do a multiplot (warning: limited to 24 plots...)
pp = dict(focus='ocean', offset=-273.15, contours=1)
#   -> see plot() documentation: https://climaf.readthedocs.io/en/latest/scripts/plot.html
mp = plot(test_llbox, **pp)

iplot(mp)

test_spaceavg = space_average(test_llbox)
p=ensemble_ts_plot(test_spaceavg)
iplot(p)

test_ensemble = ds(project='CORDEX_extent', period='1990-2010', variable='tas', gcm= 'MPI-M-MPI-ESM-LR', rcm='*')
summary(test_ensemble)
summary(test_ensemble.explore('ensemble'))

test_spaceavg = space_average(test_ensemble)
p=ensemble_ts_plot(test_spaceavg)
iplot(p)
