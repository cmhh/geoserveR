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
