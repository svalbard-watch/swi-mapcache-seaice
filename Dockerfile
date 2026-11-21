ARG PYTHON_VERSION=3.14.8

# Stage 1: Dependency resolution
FROM astral/uv:python3.14-bookworm-slim AS uv
WORKDIR /swi
COPY pyproject.toml uv.lock ./
# Export the locked, hashed set: the image installs exactly what uv.lock pins.
RUN uv export --frozen --no-dev --no-emit-project -o requirements.txt

# Stage 2: Build
FROM python:${PYTHON_VERSION}-slim AS builder
WORKDIR /swi
COPY --from=uv /swi/requirements.txt .
RUN pip install --no-cache-dir --require-hashes -r requirements.txt

# Stage 3: Runtime, on the shared cron base image (swi-cron-base). It provides the unprivileged
# swi user (uid/gid 9001, shared with the other SWI images that use the same volumes), /swi, the
# run lock, the entrypoint and the healthcheck; see https://github.com/svalbard-watch/swi-cron-base
# Its tag must match the Python version of the builder stage above.
FROM ghcr.io/svalbard-watch/swi-cron-base:1.0.0-py3.14

USER root
COPY --from=builder /usr/local/lib/python3.14/site-packages /usr/local/lib/python3.14/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# The job downloads into ./data and writes into two volumes (./export and ./metadata).
# Create the mount points owned by the job user: an empty named volume inherits the
# ownership of the directory it is mounted on, so a fresh volume is writable without any
# runtime chown.
RUN mkdir -p /swi/export /swi/metadata \
    && chown swi:swi /swi/export /swi/metadata

# The code stays owned by root: the job can create files here, not edit its own code
COPY icechart_caching.py ./run.py
COPY mapnik_map_file.xml ./mapnik_map_file.xml

# run-cron (from the base image) runs this once per start, one run at a time.
ENV SWI_CRON_COMMAND="python /swi/run.py"

USER swi
