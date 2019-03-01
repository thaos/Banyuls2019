# Examples from :
# R practice using data from the ENSEMBLES Project
# Joaquin Bedia
# http://www.value-cost.eu/sites/default/files/VALUE_TS1_D02_RIntro.pdf 

library(ncdf4)
library(maptools)

data(wrld_simpl) # loads the world map dataset
wrl <- as(wrld_simpl,"SpatialLines")


# Exercice data -----------------------------------------------------------

list_rcms <- data.frame(
  gcms = c("MOHC-HadGEM2-ES", "MOHC-HadGEM2-ES", "MPI-M-MPI-ESM-LR", "CNRM-CERFACS-CNRM-CM5"),
  #   rcms = c("RACMO22E", "RCA4", "RCA4")
  rcms = c("RACMO22E", "CCLM4-8-17", "CCLM4-8-17", "RACMO22E")
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

domain_names <- c(
  "Finland", "Norway", "Belarus", "England",
  "Germany", "France", "Italy", "Romania",
  "Greece", "Galicia", "Andalucia", "Tunisia"
)


# Create merged NetCDF ----------------------------------------------------

lfiles <-  list.files(
    path = "CORDEX", 
    pattern = paste( "tas", "MOHC-HadGEM2-ES", "RACMO22E", "\\.nc", sep = ".*" ),
    recursive = TRUE, full.names = TRUE
  )


sftlf <- list.files(
  path = "CORDEX", 
  pattern = paste( "sftlf", "MOHC-HadGEM2-ES", "RACMO22E", "\\.nc", sep = ".*" ),
  recursive = TRUE, full.names = TRUE
)[1]


system(paste("cdo -O mergetime", paste(lfiles, collapse = " "), "merged.nc", sep = " "))
system(paste("cdo -O mul merged.nc -setctomiss,0 -gec,1", sftlf, "masked.nc", sep = " "))


# Reading NetCDF ---------------------------------------------------------

# check ncdf meta-data in R
nc <- nc_open("masked.nc")
names(nc$dim)
names(nc$var)

lat <- ncvar_get(nc, "lat")
lon <- ncvar_get(nc, "lon")

# Check spatial sampling
plot(lon, lat, asp=1, cex=.4, col="grey",
     pch="+", main=("MOHC-HadGEM2-ES-SMHI-RCA4 lon-lat grid"))
lines(wrl)

rlat <- ncvar_get(nc, "rlat")
rlon <- ncvar_get(nc, "rlon") 
rot.coords <- expand.grid(rlon,rlat)

tas <- ncvar_get(nc, varid = "tas") 
str(tas) # a 3-d array (lon,lat,time)

nc_close(nc)


# Plot mean surface temp and regions of interest --------------------------

# applies function mean to margins 1 and 2 of the array
tas_mean <- apply(tas, MARGIN = c(1,2), FUN = mean)

l1 <- list("sp.lines",wrl)
t.lonlat <- data.frame(as.vector(lon), as.vector(lat), as.vector(tas_mean))
coordinates(t.lonlat) <- c(1,2)

spplot(t.lonlat, scales=list(draw=TRUE), sp.layout=list(l1),
       col.regions = rainbow(11), cuts = 10,
       main="Mean Surface Temp 1970-2099, lon/lat projection")


# Define region boxes to plots
polylist <- lapply(domains, function(dom){
  coord <- as.numeric(unlist(strsplit(dom[1], ",")))
  Polygons(list(Polygon(cbind(lon = coord[c(1, 2, 2, 1)], lat = coord[c(3, 3, 4, 4)]))), dom)
})
polylist <- SpatialPolygons(polylist)

sppolylist <- list("sp.lines", col = "red", lwd = 2, polylist)
spplot(t.lonlat, scales=list(draw=TRUE), sp.layout=list(l1, sppolylist),
       col.regions = rainbow(11), cuts = 10, cex = 0.5,
       main="Mean Max Surface Temp 1991-2000, lon/lat projection")

# Plot time-series of each region ---------------------------------------


# Function to retrirve the netcdf file for one variable ,one gcm, one rcm and one domain
get_files <- function(var, gcm, rcm, domain){
  list.files(
    path = "out", 
    pattern = paste( var, gcm, rcm, domain, "\\.nc", sep = ".*" ),
    full.names = TRUE
  )
}

# Example
ncfile <- get_files("tas", "MOHC-HadGEM2-ES", "RACMO22E", "23.625,27.375,61.625,63.375")


# Function to read the varid variable from a netcdf file.
# Output is a data.frame with one column for the year and one column for the averaged variable over the regions
read_nc1d <- function(ncfile, varid){
  #source("https://raw.githubusercontent.com/arakelian-ara/Rstat/master/time_handler.R")
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

# exeample of readind the tas variable
tas_df <- read_nc1d(ncfile, "tas")
plot(
  tas_df$year, tas_df$tas, type = "l",
  ylab = "tas(K)", xlab = "year", 
  main = "average tas for MOHC-HadGEM2-ES / RACMO22E \n
  and domain Finland (23.625,27.375,61.625,63.375)"
)

prep_df <- function(var, gcm, rcm, domain){
  files <- mapply(get_files, var = var, gcm = gcm, rcm = rcm, domain = domain)
  list_df <- lapply(files, read_nc1d, varid = var)
  for(i in seq_along(list_df)){
    if(i == 1){
      merged <- list_df[[i]]
    } else{
      merged <- merge.data.frame(merged, list_df[[i]], by = "year")
    }
  }
  print(str(merged))
  names(merged) <- c("year", paste(gcm, rcm, sep = "_"))
  return(merged)
}




# Prep data files for Guillaume and Benoit 
if(!dir.exists("TPdata") dir.create("TPdata")


var_domain <- expand.grid(var = c("tas", "pr"), domain = domains, stringsAsFactors = FALSE) 
for(i in 1:nrow(var_domain)){
  with(
    list_rcms,
    { 
      file = paste0("TPdata/", var_domain[i, ]$var, "_", var_domain[i, ]$domain, ".txt")
      print(file)
      write.table(
        prep_df(var_domain[i, ]$var, gcms, rcms, var_domain[i, ]$domain),
        file = file, row.names = FALSE 
      )
    }
  )
}

# For one variable and one region, the function plots the time-series
# for each combination of gcm / rcm 
plot_files <- function(var, gcm, rcm, domain){
  txtfile <- list.files(
    path = "TPdata",
    pattern = paste(var, domain, "\\.txt", sep = ".*" ),
    full.names = TRUE
  )
  print(txtfile)
  df <- read.table(txtfile, header = TRUE)
  ylim  <- range(df[, -1])
  xlim  <- range(df[, 1])
  pal <- rainbow(length(df) -1)
  for(i in 1:(length(df) -1)){
    if(i == 1){
      plot(
        df[, c(1, i + 1)], xlim = xlim, ylim = ylim, col = pal[i],
        type = "l", main = paste("var:", var, ", domain:", domain)
      )
    } else{
      lines(df[, c(1, i + 1)], col = pal[i]) 
    }
  }
  lines(
    df$year,
    apply(as.matrix(df[, -1]), 1, mean, na.rm = TRUE),
    lwd = 2
  )
  legend("topleft", legend = c(paste(gcm, rcm, sep = "/"), "mean"),
         col = c(pal, "black"), lty = 1)
}

with(list_rcms, plot_files("tas", gcms, rcms, domains[1]))
     
var_domain <- expand.grid(var = c("tas", "pr"), domain = domains, stringsAsFactors = FALSE) 
# par(mfrow = c(nrow(var_domain), 2))
pdf(file = "time_series.pdf")
for(i in 1:nrow(var_domain)){
  with(list_rcms, plot_files(var_domain[i, ]$var, gcms, rcms, var_domain[i, ]$domain))
}
dev.off()

# Change projection -------------------------------------------------------

library(rgdal)
str(projInfo("proj"))
str(projInfo("ellps"))
str(projInfo("datum"))

# rot_attr <- ncatt_get(nc, "rotated_pole")

library(ncdf4)
library(sf)
library(lwgeom)
library(maptools)
library(raster)
library("rnaturalearth")
library("rnaturalearthdata")
library("rgeos")

nc <- nc_open("masked.nc")
names(nc$dim)
names(nc$var)

lat <- ncvar_get(nc, "lat")
lon <- ncvar_get(nc, "lon")

rlat <- ncvar_get(nc, "rlat")
rlon <- ncvar_get(nc, "rlon") 
rot.coords <- expand.grid(lon = rlon, lat = rlat)

tas <- ncvar_get(nc, varid = "tas") 
str(tas) # a 3-d array (lon,lat,time)

nc_close(nc)

europe <- ne_countries(scale = "medium", continent = "europe", returnclass = "sf")
world <- ne_countries(scale = "medium", returnclass = "sf")
class(europe)

tas_norot <- data.frame(lon = c(lon), lat = c(lat), tas = c(tas[,,1]))
tas_norot.sf =  st_as_sf(tas_norot, coords = c('lon', 'lat'), crs = st_crs(europe))

tas_rotated <- cbind(rot.coords, tas = c(tas[,,1]))
tas_rotated.sf =  st_as_sf(tas_rotated, coords = c('lon', 'lat'))



# OK!
plot(tas_norot[, 1:2], col = !is.na(tas_norot$tas))
points(st_coordinates(europe)[, 1:2], col = "red")

# OK!
plot(tas_norot[, 1:2], col = !is.na(tas_norot$tas))
plot(europe[1], add = TRUE)

g = st_graticule(margin = 0.1)
plot(tas_norot.sf, graticule = g, axes = TRUE, reset = FALSE)
plot(europe[1], col = NA, add = TRUE)



library(sf)
# Linking to GEOS 3.5.1, GDAL 2.2.1, proj.4 4.9.3
library(lwgeom)


# Linking to liblwgeom 2.5.0dev r16016, GEOS 3.5.1, proj.4 4.9.3

# seems OK !
crs = c("+proj=longlat", "+proj=ob_tran +o_proj=longlat +o_lon_p=0 +o_lat_p=39.25 +lon_0=18 +to_meter=0.01745329")
(pole = st_point(c(0,90)))
st_transform_proj(pole, crs)

(newpole = st_point(c(-162, 39.25)))
st_transform_proj(newpole, crs)

pt1 = st_point(c(lon[2,1], lat[2,1]))
st_transform_proj(pt1, crs)

g_rot <- st_transform_proj(
  st_crop(g_rot,
    xmin = min(rlon), ymin = min(rlat),
    xmax = max(rlon), ymax = max(rlat)
  ),
  crs
)
europe_rot <- st_transform_proj(europe, crs)
world_rot <- st_transform_proj(world, crs)
tas_rot.sf <- st_transform_proj(tas_norot.sf, crs)
plot(world_rot[1], graticule = g_rot, reset = FALSE)

plot(tas_rot.sf, axes = TRUE, reset = FALSE)
plot(tas_rotated.sf, axes = TRUE, reset = FALSE)
plot(
  st_crop(europe_rot[1],
    xmin = min(rlon), ymin = min(rlat),
    xmax = max(rlon), ymax = max(rlat)
  ),
  col = NA, add = TRUE, reset = FALSE
)
plot(
  lty = 2, col = "black", add = TRUE
)

