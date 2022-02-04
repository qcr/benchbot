# Extend the BenchBot Core image
FROM benchbot/core:base

# Install Python3 for benchbot_supervisor (required due to addons integration)
RUN apt update && apt install -y python3 python3-pip

# Create a /benchbot working directory
WORKDIR /benchbot

# Install benchbot components, ordered by how expensive installation is
ARG BENCHBOT_SUPERVISOR_GIT
ARG BENCHBOT_SUPERVISOR_HASH
ENV BENCHBOT_SUPERVISOR_PATH="/benchbot/benchbot_supervisor"
RUN git clone $BENCHBOT_SUPERVISOR_GIT $BENCHBOT_SUPERVISOR_PATH && \
    pushd $BENCHBOT_SUPERVISOR_PATH && git checkout $BENCHBOT_SUPERVISOR_HASH && \
    pip3 install . 

# Expects to be built with shared_tools.Dockerfile added to the end
