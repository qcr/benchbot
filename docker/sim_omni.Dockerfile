# Extend NVIDIA's official Docker Image for Isaac Sim. Download instructions:
#   https://catalog.ngc.nvidia.com/orgs/nvidia/containers/isaac-sim
FROM  nvcr.io/nvidia/isaac-sim:2021.2.1

# Fix to address key rotation breaking APT with the official Isaac Sim image
#   https://developer.nvidia.com/blog/updating-the-cuda-linux-gpg-repository-key/
RUN apt-key adv --fetch-keys \
    https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub

# Fix scripts provided with image
RUN sed -i 's/$@/"\0"/' python.sh
RUN sed -i 's/sleep/# \0/' start_nucleus.sh

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
    pushd $BENCHBOT_SIMULATOR_PATH && git checkout $BENCHBOT_SIMULATOR_HASH && \
    /isaac-sim/kit/python/bin/python3 -m pip install -r ./.custom_deps

# Expects to be built with shared_tools.Dockerfile added to the end
