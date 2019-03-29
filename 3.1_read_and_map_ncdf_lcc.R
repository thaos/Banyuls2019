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

nc <- nc_open("/home/mcbd/correl/WORK/IMPACTCC/TP/Banyuls2019/CORDEX/historical/CNRM-CERFACS-CNRM-CM5/ALADIN63/tas/tas_EUR-11_CNRM-CERFACS-CNRM-CM5_historical_r1i1p1_CNRM-ALADIN63_v2_mon_200101-200512.nc")

# Check meta-data

print(nc)
names(nc$dim)
names(nc$var)

# Read variable (all data)

tas_mon <- ncvar_get(nc, varid = "tas") 

# Look into variable structure
 
str(tas_mon) 
dim(tas_mon)

# Extract only the first month

tas_mon1 <- ncvar_get(nc, varid = "tas", start=c(1,1,1), count=c(-1,-1,1) ) 
str(tas_mon1) 
dim(tas_mon1) 

# Read coordinates

lat <- ncvar_get(nc, "lat")
lon <- ncvar_get(nc, "lon") 
dim(lat)
dim(lon)

# Read grid variables

y <- ncvar_get(nc, "y")
x <- ncvar_get(nc, "x") 
dim(y)
dim(x)

nc_close(nc)


# Plots ****************************************


# Check spatial sampling --------------------------

plot(lon, lat, asp=1, cex=.4, col="grey",
     pch="+", main=("ALADIN63 lon-lat grid"))
lines(maps::map("world", fill = FALSE, plot = FALSE))


# Simple visualization of tas ----------------------

# Lambert conformal grid
image(x,y,tas_mon1) 
contour(x,y,tas_mon1,add=T)

# Compute clim : applies function mean to margins 1 and 2 of the array
tas_mean <- apply(tas_mon1, MARGIN = c(1,2), FUN = mean)
image(x,y,tas_mean) 
contour(x,y,tas_mean,add=T)

# Plot on lat-lon grid ----------------------

tas_lonlat <- data.frame(lon = as.vector(lon), lat = as.vector(lat), tas = as.vector(tas_mean))
coordinates(tas_lonlat) <- c("lon", "lat")

ncolor  <- 30
cuts <- cut(tas_mean,breaks = ncolor)
plot(tas_lonlat, col = rainbow(ncolor)[cuts], pch = 20)
plot(wrld_simpl, add = TRUE)
legend("topleft", legend = levels(cuts), col = rainbow(ncolor), pch = 20, bg = "white")

# Add regions of interest to plots ----------------------

# Defining regions of interest
polylist <- lapply(domains, function(dom){
  coord <- as.numeric(unlist(strsplit(dom[1], ",")))
  Polygons(list(Polygon(cbind(lon = coord[c(1, 2, 2, 1)], lat = coord[c(3, 3, 4, 4)]))), dom)
})
polylist <- SpatialPolygons(polylist)

plot(tas_lonlat, col = rainbow(ncolor)[cuts], pch = 20)
plot(wrld_simpl, add = TRUE)
plot(polylist, border = "red", lwd = 2, add = TRUE)
legend("topleft", legend = levels(cuts), col = rainbow(ncolor), pch = 20, bg = "white")


