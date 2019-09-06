library(geoserveR)
library(leaflet)

gs <- GeoServer$new()

gs$createWorkspace("statsnz")

gs$createDatastore(mb2018, "statsnz", "mb2018")

style <- import_template(
  "outline_with_label",
  name = "mb2018_with_labels", strokeColor = "#000000", strokeWidth = 0.2,
  maxScale = 600000, geometryName = "geom", labelName = "code",
  fontFamily = "Arial", fontSize = 9, fontStyle = "normal",
  fontWeight = "bold", fontColor = "#000000",
  haloSize = 1.5, haloColor = "#FFFFFF"
)

gs$createLayer("statsnz", "mb2018", "mb2018_with_labels", style)

leaflet() %>%
  fitBounds(lng1 = 164.45, lng2 = 179.35, lat1 = -48.52, lat2 = -33.22) %>%
  addTiles(
    urlTemplate = "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
  ) %>%
  addWMSTiles(
    "http://localhost:8080/geoserver/statsnz/wms?",
    layers = "mb2018_with_labels",
    options = WMSTileOptions(format = "image/png", transparent = TRUE),
    group = "mb2018"
  ) %>%
  addLayersControl(
    overlayGroups = "mb2018",
    options = layersControlOptions(collapsed = FALSE)
  )

rm(gs, style)
