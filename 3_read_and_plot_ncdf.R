# Examples from :
# R practice using data from the ENSEMBLES Project
# Joaquin Bedia
# http://www.value-cost.eu/sites/default/files/VALUE_TS1_D02_RIntro.pdf 

library(ncdf4)
library(maptools)
library(rgdal)

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

# Reading NetCDF ---------------------------------------------------------

# check ncdf meta-data in R
nc <- nc_open("ex2out/masked.nc")
names(nc$dim)
names(nc$var)

lat <- ncvar_get(nc, "lat")
lon <- ncvar_get(nc, "lon")

# Check spatial sampling
plot(lon, lat, asp=1, cex=.4, col="grey",
     pch="+", main=("MOHC-HadGEM2-ES-SMHI-RCA4 lon-lat grid"))
lines(maps::map("world", fill = FALSE, plot = FALSE))

rlat <- ncvar_get(nc, "rlat")
rlon <- ncvar_get(nc, "rlon") 
rot.coords <- expand.grid(lon = rlon, lat = rlat)

tas <- ncvar_get(nc, varid = "tas") 
str(tas) # a 3-d array (lon,lat,time)

nc_close(nc)


# Plot mean surface temp and regions of interest --------------------------

# applies function mean to margins 1 and 2 of the array
tas_mean <- apply(tas, MARGIN = c(1,2), FUN = mean)

tas_lonlat <- data.frame(lon = as.vector(lon), lat = as.vector(lat), tas = as.vector(tas_mean))
tas_rot <- cbind(rot.coords, tas = as.vector(tas_mean))


# with base package
ncolor  <- 30
cuts <- cut(tas_mean,breaks = ncolor)
with(tas_lonlat, plot(lon, lat, col = rainbow(ncolor)[cuts], pch = 20, cex =  (sin(lat * pi / 180))^2))
lines(maps::map("world", fill = FALSE, plot = FALSE))
legend("topleft", legend = levels(cuts), col = rainbow(ncolor), pch = 20, bg = "white")


# with sp package

# Defining region of interest to plots
polylist <- lapply(domains, function(dom){
  coord <- as.numeric(unlist(strsplit(dom[1], ",")))
  Polygons(list(Polygon(cbind(lon = coord[c(1, 2, 2, 1)], lat = coord[c(3, 3, 4, 4)]))), dom)
})

polylist <- SpatialPolygons(polylist)
proj4string(polylist) <- proj4string(wrld_simpl)
# and the plot function
coordinates(tas_lonlat) <- c("lon", "lat")
plot(tas_lonlat, col = rainbow(ncolor)[cuts], pch = 20)
plot(wrld_simpl, add = TRUE)
plot(polylist, border = "red", lwd = 2, add = TRUE)
legend("topleft", legend = levels(cuts), col = rainbow(ncolor), pch = 20, bg = "white")


# or with the spplot function
sppolylist <- list("sp.lines", col = "red", lwd = 2, polylist)
l1 <- list("sp.lines", wrl)
spplot(tas_lonlat, zcol = "tas", scales=list(draw=TRUE), sp.layout=list(l1, sppolylist),
       col.regions = rainbow(ncolor), cuts = ncolor - 1, cex = 0.5,
       main="Mean Max Surface Temp 1991-2000, lon/lat projection")


# ploting on regular grid with the rotated pole

# Netcdf info about the rotated pole
# int rotated_pole ;
#     rotated_pole:grid_mapping_name = "rotated_latitude_longitude" ;
#     rotated_pole:grid_north_pole_latitude = 39.25f ;
#     rotated_pole:grid_north_pole_longitude = -162.f ;

# grid_north_pole_longitude: old longitude of the new pole
# grid_north_pole_latitude: old latitude of the new pole

# projection information for rotated pole grids (PROJ4)
# +o_lat_p = new latitude of the old north pole = grid_north_pole_latitude = 39.25
# +lon_0 = longitude axis used for the rotation = 180 + grid_north_pole_longitude = 180 - 162 = 18
# +o_lon_p = after changing pole, rotate the Earth along longitude
# so that the longitude of the old pole after rotation equals to +o_lon_p 
# (by default in CORDEX, +o_lon_p = 0) 

crs = "+proj=ob_tran +o_proj=longlat +o_lon_p=0 +o_lat_p=39.25 +lon_0=18 +to_meter=0.01745329"

tas_grid <- tas_rot
coordinates(tas_grid) <- ~ lon + lat
# coerce to SpatialPixelsDataFrame
gridded(tas_grid) <- TRUE
proj4string(tas_grid) <- CRS(crs)

world_rot <- spTransform(wrld_simpl, crs)
polylist_rot <- spTransform(polylist, crs)

# plot(
#   tas_grid, axes = FALSE, col = rainbow(30),
#   breaks = seq(min(tas_mean, na.rm = TRUE), max(tas_mean, na.rm = TRUE), length.out = 31)
# )
plot(tas_grid, axes = FALSE)
llgridlines(tas_grid, xlim = range(rlon))
plot(world_rot, add = TRUE)
plot(polylist_rot, borde = "red", lwd = 2, add = TRUE)

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
  #   for windows users
  #   year <- system(paste("C:/cygwin64/bin/cdo.exe  showyear", ncfile), intern = TRUE)
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
if(!dir.exists("TPdata")) dir.create("TPdata")


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

