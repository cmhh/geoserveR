#' Build Docker container
#'
#' Build container from provided Dockerfile.  No guarantee is provided this will
#' work without issue!  Especially on Windows...
#'
#' @param tag name to give Docker image
#' @param build whether to actually run the build command or not
#'
#' @export
docker_build <- function(tag = "geoserver", build = FALSE) {
  cmd <- sprintf('docker build -t %s "%s"',
                 tag, system.file("docker", package = "geoserveR"))
  cat("\n", cmd, "\n")
  if (build) system(cmd)
}

#' Run Docker container
#'
#' Run container built via \code{docker_build}.  No guarantee is provided this
#' will work without issue!  Especially on Windows...
#'
#' @param image name of docker image
#' @param name name to give running instance
#' @param port local port
#' @param run whether or not to start an instance
#'
#' @export
docker_run <- function(image = "geoserver", name = "geoserver", port = 8080, run = FALSE) {
  cmd <- sprintf("docker run -d --rm --name %s -p %s:8080 %s",
                 name, port, image)
  cat(sprintf("\n%s\n", cmd))
  if (run) system(cmd)
}
