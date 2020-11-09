# Extend the BenchBot Core image
FROM benchbot/core:base

# Install ROS Melodic
ENV ROS_WS_PATH /benchbot/ros_ws
RUN echo "deb http://packages.ros.org/ros/ubuntu bionic main" > \
    /etc/apt/sources.list.d/ros-latest.list && \
    apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key \
    C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 && \
    apt update && apt install -y ros-melodic-desktop-full python-rosdep \
    python-rosinstall python-rosinstall-generator python-wstool \
    python-catkin-tools python-pip build-essential

# Install Vulkan
RUN wget -qO - http://packages.lunarg.com/lunarg-signing-key-pub.asc | \
    apt-key add - && wget -qO /etc/apt/sources.list.d/lunarg-vulkan-bionic.list \
    http://packages.lunarg.com/vulkan/lunarg-vulkan-bionic.list && \
    apt update && DEBIAN_FRONTEND=noninteractive apt install -yq vulkan-sdk

# Create a benchbot user with ownership of the benchbot software stack (Unreal
# for some irritating reason will not accept being run by root...) 
RUN useradd --create-home --password "" benchbot && passwd -d benchbot && \
    apt update && apt install -yq sudo && usermod -aG sudo benchbot && \
    usermod -aG root benchbot && mkdir /benchbot && \
    chown benchbot:benchbot /benchbot
USER benchbot
WORKDIR /benchbot

# Build ROS
RUN sudo rosdep init && rosdep update && \
    mkdir -p ros_ws/src && source /opt/ros/melodic/setup.bash && \
    pushd ros_ws && catkin_make && source devel/setup.bash && popd 

# Install environments from a *.zip containing pre-compiled binaries
ARG BENCHBOT_ENVS_MD5SUMS
ENV BENCHBOT_ENVS_MD5SUMS=${BENCHBOT_ENVS_MD5SUMS}
ARG BENCHBOT_ENVS_URLS
ENV BENCHBOT_ENVS_URLS=${BENCHBOT_ENVS_URLS}
ARG BENCHBOT_ENVS_SRCS
ENV BENCHBOT_ENVS_SRCS=${BENCHBOT_ENVS_SRCS}
ENV BENCHBOT_ENVS_PATH /benchbot/benchbot_envs
RUN _urls=($BENCHBOT_ENVS_URLS) && _md5s=($BENCHBOT_ENVS_MD5SUMS) && \
    _srcs=($BENCHBOT_ENVS_SRCS) && mkdir benchbot_envs && pushd benchbot_envs && \
    for i in "${!_urls[@]}"; do \
        echo "Installing environments from '${_srcs[$i]}':" && \
        echo "Downloading ... " && wget -q "${_urls[$i]}" -O "$i".zip && \
        test "${_md5s[$i]}" = $(md5sum "$i".zip | cut -d ' ' -f1) && \
        echo "Extracting ... " && unzip -q "$i".zip && rm -v "$i".zip && \
        mv "$(find . -mindepth 1 -maxdepth 1 -type d | head -n 1)" "$i" || \
        exit 1; \
    done

# Install benchbot components, ordered by how expensive installation is
ARG BENCHBOT_SUPERVISOR_GIT
ARG BENCHBOT_SUPERVISOR_HASH
ENV BENCHBOT_SUPERVISOR_PATH /benchbot/benchbot_supervisor
RUN git clone $BENCHBOT_SUPERVISOR_GIT $BENCHBOT_SUPERVISOR_PATH && \
    pushd $BENCHBOT_SUPERVISOR_PATH && git checkout $BENCHBOT_SUPERVISOR_HASH && \
    pip install . 
ARG BENCHBOT_CONTROLLER_GIT
ARG BENCHBOT_CONTROLLER_HASH
ENV BENCHBOT_CONTROLLER_PATH /benchbot/benchbot_robot_controller
RUN git clone $BENCHBOT_CONTROLLER_GIT $BENCHBOT_CONTROLLER_PATH && \
    pushd $BENCHBOT_CONTROLLER_PATH && git checkout $BENCHBOT_CONTROLLER_HASH && \
    pip install -r $BENCHBOT_CONTROLLER_PATH/requirements.txt && pushd $ROS_WS_PATH && \
    pushd src && git clone https://github.com/eric-wieser/ros_numpy.git && popd && \
    ln -sv $BENCHBOT_CONTROLLER_PATH src/ && source devel/setup.bash && catkin_make

# Record the type of backend built
ENV BENCHBOT_BACKEND_TYPE lite
