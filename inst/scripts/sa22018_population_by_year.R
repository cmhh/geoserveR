library(geoserveR)
library(leaflet)
library(sf)
library(dplyr)
library(reshape2)

# create feature class with counts as columns / attributes ---------------------
counts <- popdata %>%
  dplyr::filter(geography == "sa22018") %>%
  dplyr::select(-geography)

counts_wide <- counts %>%
  reshape2::dcast(code ~ year, value.var = "value") %>%
  data.frame

sa22018_with_counts <- sa22018 %>%
  inner_join(counts_wide, by = "code")

View(sa22018_with_counts)

# create layers ----------------------------------------------------------------
# connection details
gs <- GeoServer$new()

# create a workspace
gs$createWorkspace("statsnz")

# upload the SA2s with counts
gs$createDatastore(sa22018_with_counts, "statsnz", "sa22018_with_counts")

# create a style for each available year
years <- c(1996, 2001, 2006:2018)

for (year in years) {
  col <- sprintf("X%s", year)
  name <- sprintf("sa22018_%s", year)
  style <- create_polygon_fills(sa22018_with_counts, col, "geom", "label", pal = "YlOrRd")
  gs$createLayer("statsnz", "sa22018_with_counts", name, style)
}

# map the results --------------------------------------------------------------
# map, zoomed to NZ
m <- leaflet() %>%
  fitBounds(lng1 = 164.45, lng2 = 179.35, lat1 = -48.52, lat2 = -33.22) %>%
  addTiles(
    urlTemplate = "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
  )

# add each of the new WMS layers
for (year in years) {
  m <- m %>%
    addWMSTiles(
      "http://localhost:8080/geoserver/statsnz/wms?",
      layers = sprintf("sa22018_%s", year),
      options = WMSTileOptions(format = "image/png", transparent = TRUE),
      group = as.character(year)
    ) %>%
    hideGroup(as.character(year))
}

# add a little widget to allow toggling layers
m <- m %>%
  addLayersControl(
    overlayGroups = as.character(years),
    options = layersControlOptions(collapsed = TRUE)
  ) %>%
  showGroup(as.character(tail(years, 1)))

# show the map
m

# tidy up ----------------------------------------------------------------------
rm(gs, counts, counts_wide, sa22018_with_counts, style)
