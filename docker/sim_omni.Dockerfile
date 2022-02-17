# Extend NVIDIA's official Docker Image for Isaac Sim. Download instructions:
#   https://catalog.ngc.nvidia.com/orgs/nvidia/containers/isaac-sim
FROM  nvcr.io/nvidia/isaac-sim:2021.2.1

# Overrides to make things play nicely with the BenchBot ecosystem
SHELL ["/bin/bash", "-c"]
ENTRYPOINT []
ENV ACCEPT_EULA="Y"
ENV NO_NUCLEUS="Y"

# Install the BenchBot Simulator wrappers for 'sim_omni'
RUN apt update && apt install -y git
ARG BENCHBOT_SIMULATOR_GIT
ARG BENCHBOT_SIMULATOR_HASH
ENV BENCHBOT_SIMULATOR_PATH="/benchbot/benchbot_simulator"
RUN mkdir -p $BENCHBOT_SIMULATOR_PATH && \
    git clone $BENCHBOT_SIMULATOR_GIT $BENCHBOT_SIMULATOR_PATH && \
    pushd $BENCHBOT_SIMULATOR_PATH && git checkout $BENCHBOT_SIMULATOR_HASH

# Expects to be built with shared_tools.Dockerfile added to the end
