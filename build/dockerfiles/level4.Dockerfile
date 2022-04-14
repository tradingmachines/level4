FROM debian:buster

ARG LEVEL4_RELEASE_PATH

# level4 environment
ENV LEVEL4_HOME=/home/level4
ENV PATH=${PATH}:${LEVEL4_HOME}/bin
ENV LC_ALL=en_GB.UTF-8
ENV LANG=en_GB.UTF-8
ENV LANGUAGE=en_GB.UTF-8

# create level4 home
USER root

RUN apt update && apt upgrade -y
RUN apt install openssl ca-certificates -y

RUN mkdir -p ${LEVEL4_HOME}
RUN cd ${LEVEL4_HOME}

WORKDIR ${LEVEL4_HOME}

COPY ${LEVEL4_RELEASE_PATH} .
COPY init/level4-init.sh .

RUN useradd -Ms /bin/bash level4
RUN chown -R level4:level4 ${LEVEL4_HOME} && \
    chmod +x level4-init.sh

# setup complete, use level4 user
USER level4

ENTRYPOINT ./level4-init.sh
