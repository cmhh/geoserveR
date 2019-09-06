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

# create layers ----------------------------------------------------------------
gs <- GeoServer$new()

gs$createWorkspace("statsnz")

gs$createDatastore(sa22018_with_counts, "statsnz", "sa22018_with_counts")

years <- c(1996, 2001, 2006:2018)

for (year in years) {
  col <- sprintf("X%s", year)
  name <- sprintf("sa22018_%s", year)
  style <- create_polygon_fills(sa22018_with_counts, col, "geom", "label")
  gs$createLayer("statsnz", "sa22018_with_counts", name, style)
}

# map the results --------------------------------------------------------------

m <- leaflet() %>%
  fitBounds(lng1 = 164.45, lng2 = 179.35, lat1 = -48.52, lat2 = -33.22) %>%
  addTiles(
    urlTemplate = "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
  )

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

m <- m %>%
  addLayersControl(
    overlayGroups = as.character(years),
    options = layersControlOptions(collapsed = TRUE)
  ) %>%
  showGroup(as.character(tail(years, 1)))

# tidy up ----------------------------------------------------------------------
rm(gs, counts, counts_wide, sa22018_with_counts, style)
