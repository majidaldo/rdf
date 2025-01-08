# to run the function from a container

# should match .python-version
ARG PYVER=3.11.9
FROM python:${PYVER}-alpine
# this is a musl-based instead of glibc debian/ubuntu
# but uv doesn't manage musl-based
# might try a slimmed ubuntu
# (see below)
ARG WORKDIR=/spklrdf
#https://github.com/astral-sh/uv/pull/6834
ENV UV_PROJECT_ENVIRONMENT=${WORKDIR}/.venv
ARG UV_OPTS=--frozen --locked


RUN apk update
RUN apk add openjdk21-jre curl bash
# for convenience
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/root/.cargo/bin:/root/.local/bin
# install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
# make dir inside container same as outside (?)
WORKDIR ${WORKDIR}
# https://github.com/GoogleContainerTools/kaniko/issues/1568
# would like to use build mounts so i dont have to copy:
# RUN --mount=
# https://github.com/astral-sh/uv/issues/6890
#   no uv python build for alpine yet
# RUN uv python install
# errors if .python-version is diferent
COPY .python-version .python-version
COPY uv.lock uv.lock
COPY pyproject.toml pyproject.toml
# dont know how to recursively copy while maintianing structure!
COPY src/spklrdf/*.py src/spklrdf/
COPY *.py .
copy README.md .
run uv sync --no-group dev
# # TODO: really only want .venv. use multistage build
RUN echo "PATH=${PATH}"                         >> /etc/profile
RUN echo "source ${WORKDIR}/.venv/bin/activate" >> /etc/profile
# # make `podman run <thisimage> <.venv exe>` work
ENTRYPOINT [ "/bin/bash", "-l", "-c"]
# # default arg to above
CMD ["bash"]

