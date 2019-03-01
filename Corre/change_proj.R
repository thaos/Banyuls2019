# Changing projection -------------------------------------------------------

# With sf packages
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

g = st_graticule(ndiscr = 360)
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
  st_crop(g,
    xmin = min(lon), ymin = min(lat),
    xmax = max(lon), ymax = max(lat)
  ),
  crs
)
europe_rot <- st_transform_proj(europe, crs)
world_rot <- st_transform_proj(world, crs)
tas_rot.sf <- st_transform_proj(tas_norot.sf, crs)
plot(world_rot[1], graticule = g_rot, reset = FALSE)

plot(tas_rot.sf, graticule = g_rot, axes = TRUE, reset = FALSE)
plot(tas_rotated.sf, reset = FALSE)
plot(
  st_crop(europe_rot[1],
    xmin = min(rlon), ymin = min(rlat),
    xmax = max(rlon), ymax = max(rlat)
  ),
  col = NA, add = TRUE, reset = FALSE
)
plot(
  st_crop(g_rot,
    xmin = min(rlon), ymin = min(rlat),
    xmax = max(rlon), ymax = max(rlat)
  ),
  lty = 2, col = "black", add = TRUE,
)

# plot using sp and raster --------------------------------------------------------
library(raster)
library(rgdal)
tas_rotated_raster <- raster(
  tas[,,1], crs = crs[2],
  xmn = min(rlon), xmx = max(rlon),
  ymn = min(rlat), ymx = max(rlat)
)
plot(tas_rotated_raster)

# create spatial points data frame
tas_rotated_gridded <- tas_rotated
coordinates(tas_rotated_gridded) <- ~ lon + lat
# coerce to SpatialPixelsDataFrame
gridded(tas_rotated_gridded) <- TRUE
crs(tas_rotated_gridded) <- crs[2]



# coerce to raster
rasterDF <- raster(tas_rotated_gridded)
crs(rasterDF) <- crs[2]
rasterDF



world <- ne_countries(scale = "medium", returnclass = "sp")
world_rot <- spTransform(world, crs[2])

plot(tas_rotated_gridded, axes = FALSE)
llgridlines(tas_rotated_gridded, xlim = range(rlon))
plot(world_rot, add = TRUE)
# plot(crop(world_rot, extent(min(rlon), max(rlon), min(rlat), max(rlat))), add = TRUE)

plot(rasterDF, axes = FALSE)
llgridlines(tas_rotated_gridded, xlim = range(rlon))
plot(world_rot, add = TRUE)
# plot(crop(world_rot, extent(min(rlon), max(rlon), min(rlat), max(rlat))), add = TRUE)
