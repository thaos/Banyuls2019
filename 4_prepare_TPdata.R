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

list_rcms <- data.frame(
  gcms = c("MOHC-HadGEM2-ES", "MOHC-HadGEM2-ES", "MPI-M-MPI-ESM-LR", "CNRM-CERFACS-CNRM-CM5", "CNRM-CERFACS-CNRM-CM5"),
  #   rcms = c("RACMO22E", "RCA4", "RCA4")
  rcms = c("RACMO22E", "CCLM4-8-17", "CCLM4-8-17", "RACMO22E","ALADIN63")
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


# Plot time-series of each region ---------------------------------------


# Function to retrieve the netcdf file for one variable ,one gcm, one rcm and one domain
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
  nc <- nc_open(ncfile)
  var <- ncvar_get(nc, varid)
  year <- ncvar_get(nc, "time") %/% 10000
  nc_close(nc)
  df <- data.frame(as.numeric(year), var)
  names(df) <- c("year", varid)
  return(df)
}

# exeample of reading the tas variable
tas_df <- read_nc1d(ncfile, "tas")
plot(
  tas_df$year, tas_df$tas, type = "l",
  ylab = "tas(K)", xlab = "year", 
  main = "average tas for MOHC-HadGEM2-ES / RACMO22E \n
  and domain Finland (23.625,27.375,61.625,63.375)"
)

# merge all gcm*rcm couples for 1 var and 1 domain
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

