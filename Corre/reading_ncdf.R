# Examples from :
# R practice using data from the ENSEMBLES Project
# Joaquin Bedia
# http://www.value-cost.eu/sites/default/files/VALUE_TS1_D02_RIntro.pdf 

library(ncdf4)
library(maptools)

data(wrld_simpl) # loads the world map dataset
as(wrld_simpl,"SpatialLines") -> wrl

# check ncdf meta-data in R
nc <- nc_open("merged.nc")
names(nc$dim)
names(nc$var)

lat <- ncvar_get(nc, "lat")
lon <- ncvar_get(nc, "lon")

plot(lon, lat, asp=1, cex=.4, col="grey",
     pch="+", main=("KNMI-RACMO2 lon-lat grid"))
lines(wrl)

rlat <- ncvar_get(nc, "rlat")
rlon <- ncvar_get(nc, "rlon") 
rot.coords <- expand.grid(rlon,rlat)

tas <- ncvar_get(nc, varid = "tas") 
str(tas) # a 3-d array (lon,lat,time)
# applies function mean to margins 1 and 2 of the array
tas_mean <- apply(tas, MARGIN = c(1,2), FUN = mean)

l1 <- list("sp.lines",wrl)
t.lonlat <- data.frame(as.vector(lon), as.vector(lat), as.vector(tas_mean))
coordinates(t.lonlat) <- c(1,2)

spplot(t.lonlat, scales=list(draw=TRUE), sp.layout=list(l1),
       col.regions = rainbow(11), cuts = 10,
       main="Mean Max Surface Temp 1991-2000, lon/lat projection")

library(rgdal)
str(projInfo("proj"))
str(projInfo("ellps"))
str(projInfo("datum"))

rot_attr <- ncatt_get(nc, "rotated_pole")

list_rcms <- data.frame(
  gcms = c("MOHC-HadGEM2-ES", "MOHC-HadGEM2-ES", "MPI-M-MPI-ESM-LR"),
  rcms = c("RACMO22E", "RCA4", "RCA4")
)

domains <- c(
  "23.625,27.375,61.625,63.375",
  "7.375,11.125,61.125,62.875",
  "25.675,28.625,52.625,54.375",
  "-3.125,-0.125,52.875,54.625",
  "9.375,12.125,49.375,51.125",
  "-0.375,2.125,45.375,47.125",
  "10.375,12.875,45.625,47.375",
  "23.125,25.875,45.625,47.375",
  "20.625,22.875,38.625,40.375",
  "-8.625,-6.125,41.375,43.125",
  "-4.625,-2.375,37.125,38.875",
  "8.875,10.875,34.875,36.875",
  "-180,180,-90,90"
)



get_files <- function(var, gcm, rcm, domain){
  list.files(
    path = "./", 
    pattern = paste( var, gcm, rcm, domain, "\\.nc", sep=".*" )
  )
}

ncfile <- get_files("tas", "MOHC-HadGEM2-ES", "RACMO22E", "23.625,27.375,61.625,63.375")
nc <- nc_open(ncfile)
ncvar_get(nc, "time")

read_nc1d <- function(ncfile, varid){
  source("https://raw.githubusercontent.com/arakelian-ara/Rstat/master/time_handler.R")
  nc <- nc_open(ncfile)
  var <- ncvar_get(nc, varid)
  nc_close(nc)
  #   debug(nc_time_handler)
  #   th <- as.data.frame(nc_time_handler(ncfile))
  year <- system(paste("cdo showyear", ncfile), intern = TRUE)
  year <- unlist(strsplit(year, "\\s+")) [-1]
  df <- data.frame(as.numeric(year), var)
  names(df) <- c("year", varid)
  return(df)
}

tas_df <- read_nc1d(ncfile, "tas")
plot(tas_df$year, tas_df$tas)

# faire plot de la carte avec les region selectionnes
# faire les series temporelles pour chaque sous regions


plot_files <- function(var, gcm, rcm, domain){
  files <- get_files(var, gcm, rcm, domain)
  list_df <- lapply(files, read_nc1d, varid = var)
  ylim  <- do.call(range, lapply(list_df, function(x) x[,var]))
  xlim  <- do.call(range, lapply(list_df, function(x) x[, "year"]))
  pal <- rainbow(length(list_df))
  for(i in seq_along(list_df)){
    if(i == 1){
      plot(
        list_df[[i]], xlim = xlim, ylim = ylim, col = pal[i],
        type = "l", main = domain 
      )
      merged <- list_df[[i]]
    } else{
      lines(list_df[[i]], col = pal[i]) 
      merged <- merge.data.frame(merged, list_df[[i]], by = "year")
    }
  }
  print(str(merged))
  lines(
    merged$year,
    apply(as.matrix(merged[, -1]), 1, mean, na.rm = TRUE),
    lwd = 2
  )
}

plot_files("tas", ".*", ".*", domains[1])

