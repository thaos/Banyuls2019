# Examples from :
# R practice using data from the ENSEMBLES Project
# Joaquin Bedia
# http://www.value-cost.eu/sites/default/files/VALUE_TS1_D02_RIntro.pdf 

library(ncdf4)
library(maptools)
library(rgdal)
library(maps)
library(sp)

data(wrld_simpl) # loads the world map dataset
wrl <- as(wrld_simpl,"SpatialLines")

# Exercice data -----------------------------------------------------------

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

# Read data ************************************************************


# Open ncdf in R

nc <- nc_open("ex2out/clim.nc")

# Check meta-data

print(nc)
names(nc$dim)
names(nc$var)

# Read variables (all data)

tas <- ncvar_get(nc, varid = "tas") 

# Look into variables structure

str(tas) 
dim(tas)

# Read coordinates

lat <- ncvar_get(nc, "lat")
lon <- ncvar_get(nc, "lon") 
dim(lat)
dim(lon)

# Read grid variables

rlat <- ncvar_get(nc, "rlat")
rlon <- ncvar_get(nc, "rlon") 
dim(rlat)
dim(rlon)

nc_close(nc)


# Plots ****************************************


# Check spatial sampling --------------------------

# Rotated grid
plot(lon, lat, asp=1, cex=.4, col="grey",
     pch="+", main=("RACMO22E lon-lat grid"))
lines(maps::map("world", fill = FALSE, plot = FALSE))

# Plot on lat-lon grid with regions of interest ----------------------

tas_lonlat <- data.frame(lon = as.vector(lon), lat = as.vector(lat), tas = as.vector(tas))
coordinates(tas_lonlat) <- c("lon", "lat")

# Defining regions of interest
polylist <- lapply(domains, function(dom){
  coord <- as.numeric(unlist(strsplit(dom[1], ",")))
  Polygons(list(Polygon(cbind(lon = coord[c(1, 2, 2, 1)], lat = coord[c(3, 3, 4, 4)]))), dom)
})
polylist <- SpatialPolygons(polylist)

ncolor  <- 30
cuts <- cut(tas,breaks = ncolor)
plot(tas_lonlat, col = rainbow(ncolor)[cuts], pch = 20)
plot(wrld_simpl, add = TRUE)
plot(polylist, border = "red", lwd = 2, add = TRUE)
legend("topleft", legend = levels(cuts), col = rainbow(ncolor), pch = 20, bg = "white")

# or with the spplot function

proj4string(polylist) <- proj4string(wrld_simpl)
l1 <- list("sp.lines", wrl)
sppolylist <- list("sp.lines", col = "red", lwd = 2, polylist)
spplot(tas_lonlat, zcol = "tas", scales=list(draw=TRUE), sp.layout=list(l1, sppolylist),
       col.regions = rainbow(ncolor), cuts = ncolor - 1, cex = 0.5,
       main="Mean Max Surface Temp 1991-2000, lon/lat projection")


# Ploting on regular grid with the rotated pole ----------------------

# Netcdf info about the rotated pole
# int rotated_pole ;
#     rotated_pole:grid_mapping_name = "rotated_latitude_longitude" ;
#     rotated_pole:grid_north_pole_latitude = 39.25f ;
#     rotated_pole:grid_north_pole_longitude = -162.f ;

# grid_north_pole_longitude: old longitude of the new pole
# grid_north_pole_latitude: old latitude of the new pole

crs = "+proj=ob_tran +o_proj=longlat +o_lon_p=0 +o_lat_p=39.25 +lon_0=18 +to_meter=0.01745329"

rot.coords <- expand.grid(lon = rlon, lat = rlat)
tas_grid <- cbind(rot.coords, tas = as.vector(tas))
coordinates(tas_grid) <- ~ lon + lat
gridded(tas_grid) <- TRUE

# coerce to SpatialPixelsDataFrame
proj4string(tas_grid) <- CRS(crs)
world_rot <- spTransform(wrld_simpl, crs)
polylist_rot <- spTransform(polylist, crs)

plot(tas_grid, axes = FALSE)   ## Lola : ne marche pas !
llgridlines(tas_grid, xlim = range(rlon))
plot(world_rot, add = TRUE)
plot(polylist_rot, borde = "red", lwd = 2, add = TRUE)


