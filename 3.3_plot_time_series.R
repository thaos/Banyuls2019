# Examples from :
# R practice using data from the ENSEMBLES Project
# Joaquin Bedia
# http://www.value-cost.eu/sites/default/files/VALUE_TS1_D02_RIntro.pdf 

library(ncdf4)
library(maptools)
library(rgdal)
library(maps)
library(sp)


# Exercice data -----------------------------------------------------------

varid="tas"
gcm="MOHC-HadGEM2-ES"
rcm="RACMO22E"
domain="23.625,27.375,61.625,63.375"
path = "out"
domain_name = "Finland"

# Read data ************************************************************

pattern = paste( varid, gcm, rcm, domain, "\\.nc", sep = ".*" )
ncfile = list.files(path=path,pattern=pattern,full.names = TRUE)
nc <- nc_open(ncfile)

var <- ncvar_get(nc, varid)
year <- ncvar_get(nc, "time") %/% 10000

nc_close(nc)

df <- data.frame(as.numeric(year), var)
names(df) <- c("year", varid)

# Plot time-series ---------------------------------------

plot(
  df$year, df$tas, type = "l",
  ylab = "tas(K)", xlab = "year", 
  main = paste("Average",varid,"for",gcm,"/",rcm,
  "and domain",domain_name,sep=" ")
)

