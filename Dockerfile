#TODO:
# Change COPY directives to ADD (does extracting in same step)

# Use an official Python runtime as a parent image
FROM ubuntu:bionic

# Declare any expected ARGS from the host system
ARG TZ
ARG NVIDIA_DRIVER_VERSION
ARG CUDART_VERSION
ARG ISAAC_SDK_TGZ
ARG ISAAC_SIM_TGZ
ARG ISAAC_SIM_GITDEPS_TGZ
RUN echo "Enforcing that all required arguments are provided..." && \
    test -n "$TZ" && test -n "$NVIDIA_DRIVER_VERSION" && test -n "$CUDART_VERSION" && \
    test -n "$ISAAC_SDK_TGZ" && test -n "$ISAAC_SIM_TGZ" && test -n "$ISAAC_SIM_GITDEPS_TGZ"

# Setup a user (as Unreal for whatever wacko reason does not allow us to build
# as a root user... thanks for that...), working directory, & use bash as the
# shell
SHELL ["/bin/bash", "-c"]
RUN apt update && apt -yq install sudo gnupg2 software-properties-common && \
    rm -rf /var/apt/lists/*
RUN useradd --create-home --password "" benchbot && passwd -d benchbot && \
    usermod -aG sudo benchbot
WORKDIR /home/benchbot

# Configure some basics to get us up & running
RUN echo "$TZ" > /etc/timezone && \
    ln -s /usr/share/zoneinfo/"$TZ" /etc/localtime && \
    apt update && apt -y install tzdata && rm -rf /var/apt/lists/*

# Install ROS Melodic
# TODO: condense into 2 run commands
RUN echo "deb http://packages.ros.org/ros/ubuntu bionic main" > /etc/apt/sources.list.d/ros-latest.list 
RUN apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
RUN apt update && \
    apt install -y ros-melodic-desktop-full && rm -rf /var/apt/lists/*
RUN sudo -u benchbot -- /bin/bash -c "mkdir -p ros_ws/src && source /opt/ros/melodic/setup.bash && \
    pushd ros_ws && catkin_make && source devel/setup.bash && popd"

# Install Isaac (using local copies of licensed libraries)
ADD ${ISAAC_SDK_TGZ} isaac_sdk
RUN chown -R benchbot:benchbot ./isaac_sdk && \ 
    cd ./isaac_sdk && engine/build/scripts/install_dependencies.sh && bazel build ... && \
    rm -rf /var/apt/lists/*

# Install the Nvidia driver & Vulkan
# TODO make driver version match that of host...
# TODO what about people who have installed a driver not in the default Ubuntu repositories... hmmm...
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -yq \
    "nvidia-driver-$(echo "${NVIDIA_DRIVER_VERSION}" | sed 's/\(^[0-9]*\).*/\1/')=${NVIDIA_DRIVER_VERSION}*" && \
    rm -rf /var/apt/lists/*

# Install CUDA
# TODO full CUDA install instead of just runtime if required???
RUN apt update && apt install -y wget && rm -rf /var/apt/lists/* && \
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin && \
    mv -v cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub && \
    add-apt-repository "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/ /" && \
    apt update && apt install -y "cuda-cudart-dev-10-1=${CUDART_VERSION}" && rm -rf /var/apt/lists/* && \
    ln -sv lib /usr/local/cuda-10.1/targets/x86_64-linux/lib64 && ln -sv /usr/local/cuda-10.1/targets/x86_64-linux /usr/local/cuda

# Install Unreal Engine (& Isaac Unreal Engine Sim)
# TODO make IsaacSimProject <build_number> configurable...
ADD ${ISAAC_SIM_TGZ} isaac_sim
ADD ${ISAAC_SIM_GITDEPS_TGZ} isaac_sim/Engine/Build
RUN rm isaac_sim/Engine/Build/IsaacSimProject_1.2_Core.gitdeps.xml && \
    chown -R benchbot:benchbot isaac_sim/

# # Install BenchBot software (via git repos)
# RUN pushd ros_ws && pushd src && \
#     git clone git@bitbucket.org:acrv/benchbot_supervisor && \
#     git clone git@bitbucket.org:acrv/benchbot_simulator_retired && \
#     popd && catkin_make
# # TODO

# # Install any remaining dependencies
# # TODO
