FROM debian:bookworm

ARG LEVEL4_RELEASE_PATH
ARG LEVEL4_RPC_PORT

# level4 environment
ENV LEVEL4_HOME=/home/level4
ENV PATH=${PATH}:${LEVEL4_HOME}/bin

# setup will run as root
USER root

# install dependencies
RUN apt update && apt upgrade -y
RUN apt install openssl ca-certificates -y

# create home and working directory
RUN mkdir -p ${LEVEL4_HOME}
RUN cd ${LEVEL4_HOME}
WORKDIR ${LEVEL4_HOME}

# copy in the release and init script
COPY ${LEVEL4_RELEASE_PATH} .
COPY init.sh .

# create the level4 user and change ownership of files
RUN useradd -Ms /bin/bash level4
RUN chown -R level4:level4 ${LEVEL4_HOME} && \
    chmod +x init.sh

# setup complete, use level4 user instead of root
USER level4

# expose RPC server port
EXPOSE ${LEVEL4_RPC_PORT}

# image's entrypoint it the init script
ENTRYPOINT ./init.sh
