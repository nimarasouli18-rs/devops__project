# Dockerfile Explanation

## Overview

This Dockerfile builds the Flask backend application using a multi-stage
build. The first stage prepares Python dependency wheels, and the second
stage creates the final runtime image.

The application runs as a non-root user and is served by Gunicorn on
port 8000.

---

## Dockerfile Instructions

### `# syntax=docker/dockerfile:1`

Specifies the Dockerfile frontend syntax used by Docker BuildKit.

---

### `FROM python:3.12-slim-bookworm AS builder`

Creates the dependency build stage from the official Python 3.12 slim
image.

The stage is named `builder` so its generated dependency files can be
copied into the runtime stage.

---

### `ENV PIP_DISABLE_PIP_VERSION_CHECK=1`

Disables the pip version-check message during image build.

---

### `ENV PIP_NO_CACHE_DIR=1`

Prevents pip from storing its download cache inside image layers.

---

### `WORKDIR /build`

Sets `/build` as the working directory for the dependency build stage.

---

### `COPY app/requirements.txt ./requirements.txt`

Copies the dependency file before copying application code.

This allows Docker to reuse the dependency layer when only application
source code changes.

---

### `RUN python -m pip wheel ...`

Downloads or builds Python dependency wheels and saves them under
`/wheels`.

The wheels are copied into the final runtime stage.

---

### `FROM python:3.12-slim-bookworm AS runtime`

Starts a clean runtime stage.

Build-time files that are not copied from the builder stage are excluded
from the final image.

---

### `ENV PYTHONDONTWRITEBYTECODE=1`

Prevents Python from creating `.pyc` bytecode files inside the container.

---

### `ENV PYTHONUNBUFFERED=1`

Sends Python output directly to stdout and stderr without buffering.

This makes application logs immediately visible through Docker logs.

---

### `RUN groupadd ... && useradd ...`

Creates the system group `appgroup` and the system user `appuser`.

The application does not run as the root user.

---

### `WORKDIR /app`

Sets `/app` as the working directory of the runtime container.

---

### `COPY --from=builder /wheels /wheels`

Copies the prepared dependency wheels from the builder stage.

---

### `COPY app/requirements.txt ./requirements.txt`

Copies the dependency manifest into the runtime stage.

---

### `RUN python -m pip install ...`

Installs dependencies only from the locally prepared wheels and removes
the temporary wheel directory after installation.

---

### `COPY --chown=appuser:appgroup app/hello.py ./hello.py`

Copies the Flask application into the image and assigns ownership to the
non-root application user.

---

### `USER appuser`

Changes the runtime user from root to `appuser`.

All following runtime commands execute with this user.

---

### `EXPOSE 8000`

Documents that the Flask backend listens on TCP port 8000.

This instruction does not publish the port to the host. Port exposure
and publishing are managed by Docker Compose.

---

### `CMD [...]`

Runs the Flask application using Gunicorn.

Configuration:

- Bind address: `0.0.0.0`
- Port: `8000`
- Worker count: `1`
- Request timeout: `60` seconds
- Access logs: stdout
- Error logs: stderr
- WSGI application: `server` object from `hello.py`

The final argument `hello:server` means:

- `hello`: Python module from `hello.py`
- `server`: Flask application object

---

## Security and Optimization Measures

- Uses an official Python base image.
- Uses a multi-stage build.
- Runs as a non-root user.
- Does not copy database passwords into the image.
- Copies dependencies before source code for better build caching.
- Uses a `.dockerignore` file to reduce build context.
- Uses Gunicorn instead of the Flask development server.
- Sends application logs to Docker stdout and stderr.
