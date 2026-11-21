# Sea Ice Map Caching Container

This container is designed to fetch the latest sea ice chart from the Norwegian Meteorological Institute ([cryo.met.no](https://cryo.met.no/en/latest-ice-charts)).

---

## Environment Variables

To establish a connection with Deegree3 and control container behavior, the following environment variables can be configured:

| Variable                            | Description                                                                                     |
|-------------------------------------|-------------------------------------------------------------------------------------------------|
| `SWI-SEAICE-LAYER-FILE-NAME`        | Name of the output shapefile (default: `latest`)                                                |
| `SWI-SEAICE-LAYER-LEGEND-FILE-NAME` | Name of the output legend file (default: `/metadata/met_icechart/legend.html`). A JSON legend is also written next to it, with the extension replaced by `.json` |
| `SWI-SEAICE-MONITORING-ENDPOINT`    | URL of the endpoint to notify upon successful processing                                        |
| `DOCKER_CRON`                       | If set, the container will run the script once and then wait for manual commands (e.g., `run-cron`) |
| `SWI_CRON_MAX_SECONDS`              | Longest acceptable run. With `DOCKER_CRON`, the container turns unhealthy when a run lasts longer; `0` or unset turns any overlapping start unhealthy. See [swi-cron-base](https://github.com/svalbard-watch/swi-cron-base) |

---

## Output

The generated shapefile will be saved in `/swi/export`. Ensure this directory is mapped to the corresponding storage location on MapProxy.

---

## Usage

At the end of the execution, the file `/swi/export/reload.trigger` will be touch to trigger the reload of MapProxy and the update of the input files.

### Default Mode
Run the container once and exit after processing:
```bash
docker run -it --rm \
  -v ./tests/metadata:/swi/metadata \
  -v ./tests/data/latest_seaice:/swi/export/latest_seaice \
  swi-test-seaice
```

### Interactive Mode (with `DOCKER_CRON`)
Run the container, process the data once, and keep it open for manual re-runs with `run-cron`. The image is built on [swi-cron-base](https://github.com/svalbard-watch/swi-cron-base): only one run is active at a time, and a start while a run is active is skipped and reported by the container healthcheck:
```bash
docker run -it --rm \
  -e DOCKER_CRON=1 \
  -v ./tests/metadata:/swi/metadata \
  -v ./tests/data/latest_seaice:/swi/export/latest_seaice \
  swi-test-seaice
```
- After the initial run, trigger the script again with `docker exec <container> run-cron`.
