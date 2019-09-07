# make a layer class?
# can have a map method that returns a leaflet map with the wms already added

#' File extension
#'
#' @keywords internal
ext <- function(fname) {
  split <- strsplit(fname, ".", fixed = TRUE)[[1]]
  if (length(split) == 1) NULL
  else tail(split, 1)
}

#' Test if geopkg
#'
#' @keywords internal
isgeopkg <- function(fname) {
  fext <- ext(fname)
  if (is.null(fext)) FALSE
  else (tolower(fext) == "gpkg")
}

#' GeoServer class
#'
#' @export
#' @importFrom R6 R6Class
#' @import httr
GeoServer <- R6::R6Class(
  "GeoServer",

  public = list(
    initialize = function(server, username, password) {
      if (!missing(server)) self$server <- server
      if (!missing(username)) private$username <- username
      if (!missing(password)) private$password <- password
    },

    server = "http://localhost:8080/geoserver",

    getWorkspaces = function(workspace) {
      url <-
        if (missing(workspace))
          sprintf("%s/rest/workspaces", self$server)
        else
          sprintf("%s/rest/workspaces/%s", self$server, workspace)
      res <- self$get(url)
      if (missing(workspace))
        res$workspaces$workspace
      else
        res$workspace
    },
    getLayers = function(workspace, layer) {
      url <-
        if (missing(workspace))
          sprintf("%s/rest/layers", self$server)
        else
          sprintf("%s/rest/workspaces/%s/layers", self$server, workspace)
      res1 <- self$get(url)
      if (is.null(res1)) NULL
      else if (!"layers" %in% names(res1)) res1
      else if ((length(res1[[1]]) == 1) & (res1[[1]] == "")) list()
      else res1$layers$layer
    },
    getDatastores = function(workspace, datastore) {
      if (missing(workspace))
        stop("Must provide a workspace.")

      url <-
        if (missing(datastore))
          sprintf("%s/rest/workspaces/%s/datastores", self$server, workspace)
        else
          sprintf("%s/rest/workspaces/%s/datastores/%s", self$server, workspace, datastore)

      res1 <- self$get(url)
      if (missing(datastore))
        res2 <- res1$dataStores$dataStore
      else
        res1$dataStore
    },
    getStyles = function(workspace, layer, style) {
      if (!missing(workspace) & !missing(layer))
        stop("Cannot specify both workspace and layer.")

      url <-
        if (!missing(workspace))
          sprintf("%s/rest/workspaces/%s/styles", self$server, workspace)
        else
          sprintf("%s/rest/layers/%s/styles", self$server, layer)
      if (!missing(style)) url <- sprintf("%s/%s", url, style)

      res1 <- self$get(url)

      if (is.null(res1)) NULL
      else if (!"styles" %in% names(res1)) res1
      else if ((length(res1[[1]]) == 1) & (res1[[1]] == "")) list()
      else res1$styles$style
    },
    getSettings = function() {
      res1 <- self$get(sprintf("%s/rest/settings", self$server))
      res1$global
    },

    createWorkspace = function(workspace) {
      self$post(
        sprintf("%s/rest/workspaces", self$server),
        body = list(workspace = list(name = workspace)),
        f = function(x) x$headers$location
      )
    },
    createDatastore = function(obj, workspace, datastore = deparse(substitute(obj)),
                               file = sprintf("%s.gpkg", datastore),
                               configure = "none", update = "overwrite", charset = "UTF-8") {
      url <- sprintf(
        "%s/rest/workspaces/%s/datastores/%s/file.gpkg",
        self$server, workspace, datastore
      )
      url <- sprintf(
        "%s?configure=%s&update=%s&charset=%s&filename=%s",
        url, configure, update, charset, file
      )
      fname <- tempfile(fileext = ".gpkg")
      sf::st_write(obj, fname, datastore, quiet = TRUE)
      # API docs say there should be a header called location, but there isn't
      # self$putfile(url, fname, f = function(x) x$headers$location)
      !is.null(self$putfile(url, fname, f = function(x) x))
    },
    createLayer = function(workspace, datastore, layer, style, overwrite = FALSE) {
      if (self$layerExists(workspace, layer))
        if (overwrite)
          self$deleteLayer(workspace, layer)
        else
          stop("Layer already exists, and overwrite = FALSE.")

      url <- sprintf(
        "%s/rest/workspaces/%s/datastores/%s/featuretypes",
        self$server, workspace, datastore
      )
      body <- list(featureType = list(name = layer, nativeName = datastore))
      res1 <- self$post(url, body = body, f = function(x) x$headers$location)
      if (is.null(res1))
        stop("Failed to create featuretype.")

      if (self$styleExists(workspace, style = layer))
        self$deleteStyle(workspace, style)
      url <- sprintf(
        "%s/rest/workspaces/%s/styles?name=%s",
        self$server, workspace, layer
      )
      body <- style
      res2 <- self$post(url, body = style, f = function(x) x,
                        httr::content_type("application/vnd.ogc.sld+xml"))
      if (is.null(res2)) {
        self$deleteLayer(workspace, layer)
        stop("Failed to create style.")
      }

      url <- sprintf(
        "%s/rest/workspaces/%s/layers/%s",
        self$server, workspace, layer
      )
      res3 <- self$put(
        url,
        body = list(
          layer = list(
            defaultStyle = list(name = sprintf("%s:%s", workspace, layer))
          )
        )
      )
      if (is.null(res3)) {
        self$deleteLayer(workspace, layer)
        self$deleteStyle(workspace, style)
        stop("Failed to apply style.")
      }

      !(is.null(res3))
    },

    deleteWorkspace = function(workspace) {
      if (!self$workspaceExists(workspace))
        return(FALSE)
      url <- sprintf("%s/rest/workspaces/%s?recurse=true",
                     self$server, workspace)
      res <- self$delete(url)
      !is.null(res)
    },
    deleteDatastore = function(workspace, datastore) {
      if (!self$datastoreExists(workspace, datastore))
        return(FALSE)
      url <- sprintf("%s/rest/workspaces/%s/datastores/%s?recurse=true",
                     self$server, workspace, datastore)
      res <- self$delete(url)
      !is.null(res)
    },
    deleteLayer = function(workspace, layer) {
      if (!self$layerExists(workspace, layer))
        return(FALSE)
      url <- sprintf("%s/rest/workspaces/%s/layers/%s?recurse=true",
                     self$server, workspace, layer)
      res <- self$delete(url)
      !is.null(res)
    },
    deleteStyle = function(workspace, style) {
      if (!self$styleExists(workspace = workspace, style = style))
        return(FALSE)
      url <- sprintf("%s/rest/workspaces/%s/styles/%s?recurse=true&purge=true",
                     self$server, workspace, style)
      res <- self$delete(url)
      !is.null(res)
    },

    workspaceExists = function(workspace) {
      ws <- self$getWorkspaces()
      if (is.null(ws)) FALSE
      else workspace %in% sapply(ws, function(x) x$name)
    },
    datastoreExists = function(workspace, datastore) {
      if (missing(datastore))
        stop("Please provide a datastore name.")
      ds <- self$getDatastores(workspace)
      if (is.null(ds)) FALSE
      else datastore %in% sapply(ds, function(x) x$name)
    },
    styleExists = function(workspace, layer, style) {
      if (missing(style))
        stop("Please provide a style name.")
      ss <- self$getStyles(workspace, layer)
      if (is.null(ss)) FALSE
      else style %in% sapply(ss, function(x) x$name)
    },
    layerExists = function(workspace, layer) {
      if (missing(layer))
        stop("Please provide a layer name.")
      ll <- self$getLayers(workspace)
      if (is.null(ll)) FALSE
      else layer %in% sapply(ll, function(x) x$name)
    },

    get = function(url, ..., okay = c(200), f = httr::content) {
      res <- httr::GET(url, config = private$auth(), ...)
      if (!res$status_code %in% okay) NULL
      else f(res)
    },
    post = function(url, ..., body, encode = "json", okay = c(201), f = httr::content) {
      res <- httr::POST(url, config = private$auth(), ..., body = body, encode = encode)
      assign("foo", list(url, body, encode, res), envir = .GlobalEnv)
      if (!res$status_code %in% okay) NULL
      else f(res)
    },
    put = function(url, ..., body, encode = "json", okay = c(200), f = httr::content) {
      res <- httr::PUT(url, config = private$auth(), ..., body = body, encode = encode)
      if (!res$status_code %in% okay) NULL
      else f(res)
    },
    putfile = function(url, fname, okay = c(201), f = function(x) x) {
      res <- httr::PUT(url, config = private$auth(), body = upload_file(fname))
      if (!res$status_code %in% okay) NULL
      else f(res)
    },
    delete = function(url, ..., body = NULL, encode = "json", okay = c(200), f = function(x) x) {
      res <- httr::DELETE(url, config = private$auth(), ..., body = body, encode = encode)
      if (!res$status_code %in% okay) NULL
      else f(res)
    }
  ),

  private = list(
    username = "admin",
    password = "geoserver",
    auth = function() httr::authenticate(private$username, private$password, "basic")
  )
)
