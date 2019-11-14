#TODO:
# Change COPY directives to ADD (does extracting in same step)

# Use an official Python runtime as a parent image
FROM ubuntu:bionic

# Declare any expected ARGS from the host system
ARG TZ
ARG NVIDIA_DRIVER_VERSION
ARG CUDA_VERSION
ARG CUDA_VERSION_SHORT
ARG ISAAC_SDK_TGZ
ARG ISAAC_SIM_TGZ
ARG ISAAC_SIM_GITDEPS_TGZ
RUN echo "Enforcing that all required arguments are provided..." && \
    test -n "$TZ" && test -n "$NVIDIA_DRIVER_VERSION" && test -n "$CUDA_VERSION" && \
    test -n "$CUDA_VERSION_SHORT" && test -n "$ISAAC_SDK_TGZ" && \
    test -n "$ISAAC_SIM_TGZ" && test -n "$ISAAC_SIM_GITDEPS_TGZ"

# Setup a user (as Unreal for whatever wacko reason does not allow us to build
# as a root user... thanks for that...), working directory, & use bash as the
# shell
SHELL ["/bin/bash", "-c"]
RUN apt update && apt -yq install sudo wget gnupg2 software-properties-common && \
    rm -rf /var/apt/lists/*
RUN useradd --create-home --password "" benchbot && passwd -d benchbot && \
    usermod -aG sudo benchbot
WORKDIR /home/benchbot

# Configure some basics to get us up & running
RUN echo "$TZ" > /etc/timezone && \
    ln -s /usr/share/zoneinfo/"$TZ" /etc/localtime && \
    apt update && apt -y install tzdata && rm -rf /var/apt/lists/*

# Install ROS Melodic
ENV ROS_WS_PATH /home/benchbot/ros_ws
RUN echo "deb http://packages.ros.org/ros/ubuntu bionic main" > /etc/apt/sources.list.d/ros-latest.list && \
    apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 && \
    apt update && apt install -y ros-melodic-desktop-full && rm -rf /var/apt/lists/*

# Install Isaac (using local copies of licensed libraries)
ENV ISAAC_SDK_PATH /home/benchbot/isaac_sdk
ADD ${ISAAC_SDK_TGZ} ${ISAAC_SDK_PATH}

# Install the Nvidia driver & Vulkan
# TODO what about people who have installed a driver not in the default Ubuntu repositories... hmmm...
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,display,graphics,utility
RUN wget -qO - http://packages.lunarg.com/lunarg-signing-key-pub.asc | apt-key add - && \
    wget -qO /etc/apt/sources.list.d/lunarg-vulkan-bionic.list http://packages.lunarg.com/vulkan/lunarg-vulkan-bionic.list && \
    apt update && DEBIAN_FRONTEND=noninteractive apt install -yq \
    "nvidia-driver-$(echo "${NVIDIA_DRIVER_VERSION}" | sed 's/\(^[0-9]*\).*/\1/')=${NVIDIA_DRIVER_VERSION}*" && \
    DEBIAN_FRONTEND=noninteractive apt install -yq vulkan-sdk && \
    rm -rf /var/apt/lists/*

# Install CUDA
# TODO full CUDA install seems excessive, can this be trimmed down?
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin && \
    mv -v cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub && \
    add-apt-repository "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/ /" && \
    apt update && apt install -y "cuda-${CUDA_VERSION_SHORT}=${CUDA_VERSION}" && rm -rf /var/apt/lists/* && \
    ln -sv lib /usr/local/cuda-"$(echo ${CUDA_VERSION_SHORT} | tr - .)"/targets/x86_64-linux/lib64 && \
    ln -sv /usr/local/cuda-"$(echo ${CUDA_VERSION_SHORT} | tr - .)"/targets/x86_64-linux /usr/local/cuda

# Install Unreal Engine (& Isaac Unreal Engine Sim)
# TODO make IsaacSimProject <build_number> configurable...
ENV ISAAC_SIM_PATH /home/benchbot/isaac_sim
ADD ${ISAAC_SIM_TGZ} ${ISAAC_SIM_PATH}
ADD ${ISAAC_SIM_GITDEPS_TGZ} isaac_sim/Engine/Build

# Install any remaining software
RUN apt update && apt install -y git python-catkin-tools python-pip \
    python-rosinstall-generator python-wstool

# Perform all user setup steps
RUN chown -R benchbot:benchbot *
USER benchbot
RUN mkdir -p ros_ws/src && source /opt/ros/melodic/setup.bash && \
    pushd ros_ws && catkin_make && source devel/setup.bash && popd && \
    pushd "$ISAAC_SDK_PATH" && \
    engine/build/scripts/install_dependencies.sh && bazel build ... && \
    rm -rf /var/apt/lists/* && popd && \
    rm isaac_sim/Engine/Build/IsaacSimProject_1.2_Core.gitdeps.xml

# TODO we CANNOT UNDER ANY CIRCUMSTANCES release this software with this line in
# it (it manually ignores a licence). I have added this line here because I was
# stuck in a situation where every time I added stuff to the DockerFile, the 
# annoying manual license accept prompt meant the entire Isaac UnrealEngine SIM
# had to rebuilt from scratch.... It was hindering development way too much...
RUN cd isaac_sim && \
    sed -i 's/\[ -f.*1\.2\.gitdeps\.xml \];/\[ 1 == 2 \] \&\& \0/' Setup.sh && \
    ./Setup.sh &&  ./GenerateProjectFiles.sh && ./GenerateTestRobotPaths.sh && \
    make && make IsaacSimProjectEditor

# Install our benchbot software
# TODO we CANNOT RELEASE THIS we way it is below. It takes my private SSH key
# and adds it into the Docker image layers, exposing it to other areas of your
# computer. While not disastrous, it is bad from a security standpoint to
# do this with your private key. This problem will "go away" as we get to 
# release & things move to public repos (i.e. no key needed) but for now we
# should probably create a dummy bitbucket account with a shared private key
# in the "benchbot_devel" (to keep install "just working" for anyone using the
# repo)
ENV BENCHBOT_SIMULATOR_PATH /home/benchbot/benchbot_simulator
ENV BENCHBOT_ENVS_PATH /home/benchbot/benchbot_envs
ENV BENCHBOT_SUPERVISOR_PATH /home/benchbot/benchbot_supervisor
ADD --chown=benchbot:benchbot id_rsa .ssh/id_rsa
RUN touch .ssh/known_hosts && ssh-keyscan bitbucket.org >> .ssh/known_hosts 

# TODO remove Ben's debugging toolset!
# TODO add iputils-ping
RUN sudo apt update && sudo apt install -y vim ipython tmux

# Ordered by how expensive installation is ...
RUN git clone --branch develop git@bitbucket.org:acrv/benchbot_envs_devel $BENCHBOT_ENVS_PATH && \
    pushd $BENCHBOT_ENVS_PATH && git checkout $BENCHBOT_ENVS_HASH && ./install && cd $ISAAC_SIM_PATH && \
    (./Engine/Binaries/Linux/UE4Editor IsaacSimProject -run=DerivedDataCache -fill || true)
RUN git clone --branch develop git@bitbucket.org:acrv/benchbot_simulator $BENCHBOT_SIMULATOR_PATH && \
    pushd $BENCHBOT_SIMULATOR_PATH && git checkout $BENCHBOT_SIMULATOR_HASH && \
    source $ROS_WS_PATH/devel/setup.bash && .isaac_patches/apply_patches && \
    ./bazelros build //apps/benchbot_simulator
RUN git clone --branch develop git@bitbucket.org:acrv/benchbot_supervisor $BENCHBOT_SUPERVISOR_PATH && \
    pushd $BENCHBOT_SUPERVISOR_PATH && git checkout $BENCHBOT_SUPERVISOR_HASH && \
    pip install -r $BENCHBOT_SUPERVISOR_PATH/requirements.txt && pushd $ROS_WS_PATH && \
    pushd src && git clone https://github.com/eric-wieser/ros_numpy.git && popd && \
    ln -sv $BENCHBOT_SUPERVISOR_PATH src/ && source devel/setup.bash && catkin_make

# RUN rm -rf .ssh 
