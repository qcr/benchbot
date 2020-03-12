# Extend the BenchBot Core image
FROM benchbot/core:base

# Install ROS Melodic
ENV ROS_WS_PATH /benchbot/ros_ws
RUN echo "deb http://packages.ros.org/ros/ubuntu bionic main" > \
    /etc/apt/sources.list.d/ros-latest.list && \
    apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key \
    C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 && \
    apt update && apt install -y ros-melodic-desktop-full

# Install Vulkan
RUN wget -qO - http://packages.lunarg.com/lunarg-signing-key-pub.asc | \
    apt-key add - && wget -qO /etc/apt/sources.list.d/lunarg-vulkan-bionic.list \
    http://packages.lunarg.com/vulkan/lunarg-vulkan-bionic.list && \
    apt update && DEBIAN_FRONTEND=noninteractive apt install -yq vulkan-sdk

# Install any remaining extra software
RUN apt update && apt install -y git python-catkin-tools python-pip \
    python-rosinstall-generator python-wstool

# Create a benchbot user with ownership of the benchbot software stack (Unreal
# for some irritating reason will not accept being run by root...) 
RUN useradd --create-home --password "" benchbot && passwd -d benchbot && \
    apt update && apt install -yq sudo && usermod -aG sudo benchbot && \
    usermod -aG root benchbot && mkdir /benchbot && \
    chown benchbot:benchbot /benchbot
USER benchbot
WORKDIR /benchbot

# Install Isaac (using local copies of licensed libraries)
ARG ISAAC_SDK_TGZ
ENV ISAAC_SDK_PATH /benchbot/isaac_sdk
ADD --chown=benchbot:benchbot ${ISAAC_SDK_TGZ} ${ISAAC_SDK_PATH}

# Build ROS & Isaac
RUN mkdir -p ros_ws/src && source /opt/ros/melodic/setup.bash && \
    pushd ros_ws && catkin_make && source devel/setup.bash && popd && \
    pushd "$ISAAC_SDK_PATH" && \
    engine/build/scripts/install_dependencies.sh && bazel build ... && \
    bazel build ...

# Install environments from a *.zip containing pre-compiled binaries
ARG BENCHBOT_ENVS_MD5SUM
ENV BENCHBOT_ENVS_MD5SUM=${BENCHBOT_ENVS_MD5SUM}
ARG BENCHBOT_ENVS_URL
ENV BENCHBOT_ENVS_URL=${BENCHBOT_ENVS_URL}
ENV BENCHBOT_ENVS_PATH /benchbot/benchbot_envs
RUN echo "Downloading environments ... " && wget -q $BENCHBOT_ENVS_URL -O benchbot_envs.zip && \
    test $BENCHBOT_ENVS_MD5SUM = $(md5sum benchbot_envs.zip | cut -d' ' -f1) && \
    echo "Extracting environments ... " && unzip -q benchbot_envs.zip && \
    rm -v benchbot_envs.zip && mv LinuxNoEditor $BENCHBOT_ENVS_PATH
ENV BENCHBOT_ENVS_MD5SUM $BENCHBOT_ENVS_MD5SUM

# Install benchbot components, ordered by how expensive installation is
ARG BENCHBOT_SIMULATOR_GIT
ARG BENCHBOT_SIMULATOR_HASH
ENV BENCHBOT_SIMULATOR_PATH /benchbot/benchbot_simulator
RUN git clone $BENCHBOT_SIMULATOR_GIT $BENCHBOT_SIMULATOR_PATH && \
    pushd $BENCHBOT_SIMULATOR_PATH && git checkout $BENCHBOT_SIMULATOR_HASH && \
    source $ROS_WS_PATH/devel/setup.bash && .isaac_patches/apply_patches && \
    ./bazelros build //apps/benchbot_simulator
ARG BENCHBOT_SUPERVISOR_GIT
ARG BENCHBOT_SUPERVISOR_HASH
ENV BENCHBOT_SUPERVISOR_PATH /benchbot/benchbot_supervisor
RUN git clone $BENCHBOT_SUPERVISOR_GIT $BENCHBOT_SUPERVISOR_PATH && \
    pushd $BENCHBOT_SUPERVISOR_PATH && git checkout $BENCHBOT_SUPERVISOR_HASH && \
    pip install -r $BENCHBOT_SUPERVISOR_PATH/requirements.txt && pushd $ROS_WS_PATH && \
    pushd src && git clone https://github.com/eric-wieser/ros_numpy.git && popd && \
    ln -sv $BENCHBOT_SUPERVISOR_PATH src/ && source devel/setup.bash && catkin_make

