curl \
  -d '{"workspace":{"name":"statsnz"}}' \
  -u admin:geoserver\
  -H "Content-Type: application/json" -X POST \
  http://localhost:8080/geoserver/rest/workspaces