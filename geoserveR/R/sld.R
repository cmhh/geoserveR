#' left trim
#'
#' @keywords internal
ltrim <- function(str) {
  if (nchar(str) == 0 | substr(str, 1, 1) != " ") str
  else ltrim(substr(str, 2, nchar(str)))
}

#' right trim
#'
#' @keywords internal
rtrim <- function(str) {
  if (nchar(str) == 0 | substr(str, nchar(str), nchar(str)) != " ") str
  else rtrim(substr(str, 1, nchar(str) - 1))
}

#' trim
#'
#' @keywords internal
trim <- function(str) ltrim(rtrim(str))

#' Polygon fill rule for sld
#'
#' @export
fill_rule <- function(op = c("<", "<=", ">", ">=", "==", "--"),
                      column, value, color, opacity = 0.7, title) {
  if (op == "--" & length(value) < 2)
    stop("Rule 'PropertyIsBetween' requires a value of the form c(lo, hi)")

  symbol <-
    if (op == "<") "&lt;"
    else if (op == "<=") "&#x2264;"
    else if (op == ">")  "&gt;"
    else if (op == ">=") "&#x2265;"
    else if (op == "==") "="
    else if (op == "!=") "&#x2260;"
    else if (op == "--") "-"

  relation <-
    if (op == "<") "PropertyIsLessThan"
    else if (op == "<=") "PropertyIsLessThanOrEqualTo"
    else if (op == ">")  "PropertyIsGreaterThan"
    else if (op == ">=") "PropertyIsGreaterThanOrEqualTo"
    else if (op == "==") "PropertyIsEqualTo"
    else if (op == "!=") "PropertyIsNotEqualTo"
    else if (op == "--") "PropertyIsBetween"

  if (missing(title))
    title <-
      if (op == "--") sprintf("%s%s%s", value[1], symbol, value[2])
      else sprintf("%s %s", symbol, value)

  rule <-
    if (op == "--") {
      lo <- sprintf("<ogc:LowerBoundary><ogc:literal>%s</ogc:literal></ogc:LowerBoundary>", value[1])
      hi <- sprintf("<ogc:UpperBoundary><ogc:literal>%s</ogc:literal></ogc:UpperBoundary>", value[2])
      sprintf("%s\n      %s", lo, hi)
    } else
      sprintf("<ogc:literal>%s</ogc:literal>", value)

    sprintf(
'<Rule>
  <Title>%s</Title>
  <ogc:Filter>
    <ogc:%s>
      <ogc:PropertyName>%s</ogc:PropertyName>
      %s
    </ogc:%s>
  </ogc:Filter>
  <PolygonSymbolizer>
    <Fill>
      <CssParameter name="fill">%s</CssParameter>
      <CssParameter name="fill-opacity">%s</CssParameter>
    </Fill>
  </PolygonSymbolizer>
</Rule>', title, relation, column, rule, relation, color, opacity)
}

#' Sequential palette
#'
#' @importFrom RColorBrewer brewer.pal
#'
#' @keywords internal
sequential_palette <- function(n = 5, pal = "Blues") {
  if (!pal %in% c("Blues", "BuGn", "BuPu", "GnBu", "Greens", "Greys", "Oranges",
                  "OrRd", "PuBu", "PuBuGn", "PuRd", "Purples", "RdPu", "Reds",
                  "YlGn", "YlGnBu", "YlOrBr", "YlOrRd"))
    stop("Invalid palette.")
  p <- colorRamp(brewer.pal(9, pal), interpolate = "spline")(seq(0, 1, 1 / (n - 1)))
  apply(p, 1, function(x) rgb(x[1], x[2], x[3], maxColorValue = 255))
}

#' Create SLD polygon fills
#'
#' @export
create_polygon_fills <- function(data, value_column, geometry_column, label_column,
                                 n = 5, pal = "Blues", opacity = 0.7,
                                 title = value_column, abstract = value_column,
                                 stroke_color = "#000000", stroke_width = 0.2,
                                 max_scale = 600000, font_family = "Arial",
                                 font_size = 9, font_style = "normal",
                                 font_weight = "bold", font_color = "#000000",
                                 halo_size = 1.5, halo_color = "#FFFFFF") {
  cols <- sequential_palette(n, pal)
  breaks <- quantile(unlist(data.frame(data)[,value_column], use.names = FALSE),
                     probs = seq(0, 1, 1 / n),
                     names = FALSE)[-1]
  rules <- lapply(1:(n - 1), function(x){
    if (x == 1)
      fill_rule("<", value_column, breaks[x], cols[x], opacity)
    else
      fill_rule("--", value_column, c(breaks[x - 1], breaks[x]), cols[x], opacity)
  })
  rules[[length(rules) + 1]] <-
    fill_rule(">=", value_column, breaks[n - 1], cols[n], opacity)
  rules <- paste(rules, collapse = "\n")

  import_template(
    "filled_polygon_with_label",
    name = value_column, title = title, abstract = abstract, fillRules = rules,
    strokeColor = stroke_color, strokeWidth = stroke_width,
    maxScale = max_scale, geometryName = geometry_column, labelName = label_column,
    fontFamily = font_family, fontSize = 9, fontStyle = "normal",
    fontWeight = font_weight, fontColor = font_color,
    haloSize = halo_size, haloColor = halo_color
  )
}

#' Import sld template
#'
#' @details
#' For every named argument, \code{name = value}, replace \code{\{\{ name \}\}}
#' in \code{styles/<template.sld} with \code{value}.
#'
#' @param template name of template
#' @param ... named arguments
#'
#' @export
#'
#' @examples
#' import_template(
#'   "outline_with_label",
#'   name = "mb2018outline", strokeColor = "#000000", strokeWidth = 1,
#'   maxScale = 600000, geometryName = "geom", labelName = "code",
#'   fontFamily = "Arial", fonSize = 10, fontStyle = "normal",
#'   fontWeight = "bold", fontColor = "#000000"
#' )
import_template <- function(template, ...) {
  args <- list(...)

  if (any(is.null(names(args))))
    stop("Arguments must be named.")

  template_dir <- system.file("styles", package = "geoserveR")
  if (!sprintf("%s.sld", template) %in% dir(template_dir))
    stop("No such template.")

  sld <- readLines(sprintf("%s/%s.sld", template_dir, template))

  for (arg in names(args))
    sld <- gsub(sprintf("{{ %s }}", arg), args[[arg]], sld, fixed = TRUE)

  paste(sld, collapse = "\n")
}
