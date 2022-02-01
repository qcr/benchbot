# Extend the BenchBot Core image
FROM benchbot/core:base

# Install ROS Melodic
RUN echo "deb http://packages.ros.org/ros/ubuntu bionic main" > \
    /etc/apt/sources.list.d/ros-latest.list && \
    apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key \
    C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654 && \
    apt update && apt install -y ros-melodic-desktop-full python-rosdep \
    python-rosinstall python-rosinstall-generator python-wstool \
    python-catkin-tools python-pip build-essential

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
