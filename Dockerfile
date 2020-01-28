# Use an official Ubuntu runtime as a parent image
FROM ubuntu:bionic

# Declare any expected ARGS from the host system
ARG TZ
ARG NVIDIA_DRIVER_VERSION
ARG CUDA_VERSION
ARG CUDA_VERSION_SHORT

ARG ISAAC_SDK_TGZ

ARG BENCHBOT_SIMULATOR_HASH
ARG BENCHBOT_SUPERVISOR_HASH

ARG BENCHBOT_ENVS_MD5SUM
ARG BENCHBOT_ENVS_URL

RUN echo "Enforcing that all required arguments are provided..." && \
    test -n "$TZ" && test -n "$NVIDIA_DRIVER_VERSION" && test -n "$CUDA_VERSION" && \
    test -n "$CUDA_VERSION_SHORT" && test -n "$ISAAC_SDK_TGZ" && \
    test -n "$BENCHBOT_SIMULATOR_HASH" && test -n "$BENCHBOT_SUPERVISOR_HASH" && \
    test -n "$BENCHBOT_ENVS_MD5SUM" && test -n "$BENCHBOT_ENVS_URL"

# Setup some useful default configs & a user (not sure this is necessary now 
# we've ditched installing Unreal...)
SHELL ["/bin/bash", "-c"]
RUN apt update && apt -yq install sudo wget gnupg2 software-properties-common
RUN useradd --create-home --password "" benchbot && passwd -d benchbot && \
    usermod -aG sudo benchbot
WORKDIR /home/benchbot

# Configure some basics to get us up & running
RUN echo "$TZ" > /etc/timezone && ln -s /usr/share/zoneinfo/"$TZ" /etc/localtime && \
    apt update && apt -y install tzdata

# Install ROS Melodic
ENV ROS_WS_PATH /home/benchbot/ros_ws
RUN echo "deb http://packages.ros.org/ros/ubuntu bionic main" > /etc/apt/sources.list.d/ros-latest.list && \
    apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 && \
    apt update && apt install -y ros-melodic-desktop-full

# Install Isaac (using local copies of licensed libraries)
ENV ISAAC_SDK_PATH /home/benchbot/isaac_sdk
ADD ${ISAAC_SDK_TGZ} ${ISAAC_SDK_PATH}

# Install Nvidia software (Cuda & drivers)
# TODO handle driver versions from graphics drivers PPA
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,display,graphics,utility
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-ubuntu1804.pin && \
    mv -v cuda-ubuntu1804.pin /etc/apt/preferences.d/cuda-repository-pin-600 && \
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub && \
    add-apt-repository "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/ /" && \
    apt update && DEBIAN_FRONTEND=noninteractive apt install -yq \
    "nvidia-driver-$(echo "${NVIDIA_DRIVER_VERSION}" | sed 's/\(^[0-9]*\).*/\1/')=${NVIDIA_DRIVER_VERSION}*" \
    "cuda-${CUDA_VERSION_SHORT}=${CUDA_VERSION}" && \
    ln -sv lib /usr/local/cuda-"$(echo ${CUDA_VERSION_SHORT} | tr - .)"/targets/x86_64-linux/lib64 && \
    ln -sv /usr/local/cuda-"$(echo ${CUDA_VERSION_SHORT} | tr - .)"/targets/x86_64-linux /usr/local/cuda

# Install Vulkan
RUN wget -qO - http://packages.lunarg.com/lunarg-signing-key-pub.asc | apt-key add - && \
    wget -qO /etc/apt/sources.list.d/lunarg-vulkan-bionic.list http://packages.lunarg.com/vulkan/lunarg-vulkan-bionic.list && \
    apt update && DEBIAN_FRONTEND=noninteractive apt install -yq vulkan-sdk

# Install any remaining extra software
RUN apt update && apt install -y git python-catkin-tools python-pip \
    python-rosinstall-generator python-wstool

# Perform setup steps for the "benchbot" user
RUN chown -R benchbot:benchbot *
USER benchbot
RUN mkdir -p ros_ws/src && source /opt/ros/melodic/setup.bash && \
    pushd ros_ws && catkin_make && source devel/setup.bash && popd && \
    pushd "$ISAAC_SDK_PATH" && \
    engine/build/scripts/install_dependencies.sh && bazel build ...

# Install our benchbot software
# TODO we CANNOT RELEASE THIS we way it is below. It takes my private SSH key
# and adds it into the Docker image layers, exposing it to other areas of your
# computer. While not disastrous, it is bad from a security standpoint to
# do this with your private key. This problem will "go away" as we get to 
# release & things move to public repos (i.e. no key needed) but for now we
# should probably create a dummy bitbucket account with a shared private key
# in the "benchbot_devel" (to keep install "just working" for anyone using the
# repo)
# TODO maybe just give the repos public access & be done with it???
ENV BENCHBOT_SIMULATOR_PATH /home/benchbot/benchbot_simulator
ENV BENCHBOT_ENVS_PATH /home/benchbot/benchbot_envs
ENV BENCHBOT_SUPERVISOR_PATH /home/benchbot/benchbot_supervisor
ADD --chown=benchbot:benchbot id_rsa .ssh/id_rsa
RUN touch .ssh/known_hosts && ssh-keyscan bitbucket.org >> .ssh/known_hosts 

# TODO remove Ben's debugging toolset!
RUN sudo apt update && sudo apt install -y vim ipython tmux iputils-ping

# Ordered by how expensive installation is ...
# TODO this is brittle in that branch is hard coded here, but we got the *_HASH values from a branch
# which is hard coded separately in the install script (if they don't match... BOOM... bad things...)
# RUN git clone --branch develop git@bitbucket.org:acrv/benchbot_envs_devel $BENCHBOT_ENVS_PATH && \
#     pushd $BENCHBOT_ENVS_PATH && git checkout $BENCHBOT_ENVS_HASH && ./install && cd $ISAAC_SIM_PATH && \
#     (./Engine/Binaries/Linux/UE4Editor IsaacSimProject -run=DerivedDataCache -fill || true)
RUN git clone --branch develop git@bitbucket.org:acrv/benchbot_simulator $BENCHBOT_SIMULATOR_PATH && \
    pushd $BENCHBOT_SIMULATOR_PATH && git checkout $BENCHBOT_SIMULATOR_HASH && \
    source $ROS_WS_PATH/devel/setup.bash && .isaac_patches/apply_patches && \
    ./bazelros build //apps/benchbot_simulator
RUN git clone --branch develop git@bitbucket.org:acrv/benchbot_supervisor $BENCHBOT_SUPERVISOR_PATH && \
    pushd $BENCHBOT_SUPERVISOR_PATH && git checkout $BENCHBOT_SUPERVISOR_HASH && \
    pip install -r $BENCHBOT_SUPERVISOR_PATH/requirements.txt && pushd $ROS_WS_PATH && \
    pushd src && git clone https://github.com/eric-wieser/ros_numpy.git && popd && \
    ln -sv $BENCHBOT_SUPERVISOR_PATH src/ && source devel/setup.bash && catkin_make

# Install environments from a *.zip containing pre-compiled binaries
RUN wget $BENCHBOT_ENVS_URL -O benchbot_envs.zip && unzip -q benchbot_envs.zip && \
    rm -v benchbot_envs.zip && mv LinuxNoEditor $BENCHBOT_ENVS_PATH

# TODO Remove this SSH stuff...
RUN rm -rf .ssh 
