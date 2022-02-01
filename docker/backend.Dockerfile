# Extend the BenchBot Core image
FROM benchbot/core:base

# Install ROS Melodic
ENV ROS_WS_PATH="/benchbot/ros_ws"
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

# Build a ROS Catkin workspace
RUN sudo rosdep init && rosdep update && \
    mkdir -p ros_ws/src && source /opt/ros/melodic/setup.bash && \
    pushd ros_ws && catkin_make && source devel/setup.bash && popd 

# Install benchbot components, ordered by how expensive installation is
ARG BENCHBOT_MSGS_GIT
ARG BENCHBOT_MSGS_HASH
ENV BENCHBOT_MSGS_HASH="$BENCHBOT_MSGS_HASH"
ENV BENCHBOT_MSGS_PATH="/benchbot/benchbot_msgs"
RUN git clone $BENCHBOT_MSGS_GIT $BENCHBOT_MSGS_PATH && \
    pushd $BENCHBOT_MSGS_PATH && git checkout $BENCHBOT_MSGS_HASH && \
    pip install -r requirements.txt && pushd $ROS_WS_PATH && \
    ln -sv $BENCHBOT_MSGS_PATH src/ && source devel/setup.bash && catkin_make
ARG BENCHBOT_SUPERVISOR_GIT
ARG BENCHBOT_SUPERVISOR_HASH
ENV BENCHBOT_SUPERVISOR_PATH="/benchbot/benchbot_supervisor"
RUN git clone $BENCHBOT_SUPERVISOR_GIT $BENCHBOT_SUPERVISOR_PATH && \
    pushd $BENCHBOT_SUPERVISOR_PATH && git checkout $BENCHBOT_SUPERVISOR_HASH && \
    pip3 install . 
ARG BENCHBOT_CONTROLLER_GIT
ARG BENCHBOT_CONTROLLER_HASH
ENV BENCHBOT_CONTROLLER_PATH="/benchbot/benchbot_robot_controller"
RUN git clone $BENCHBOT_CONTROLLER_GIT $BENCHBOT_CONTROLLER_PATH && \
    pushd $BENCHBOT_CONTROLLER_PATH && git checkout $BENCHBOT_CONTROLLER_HASH && \
    pip install -r requirements.txt && pushd $ROS_WS_PATH && \
    pushd src && git clone https://github.com/eric-wieser/ros_numpy.git && popd && \
    ln -sv $BENCHBOT_CONTROLLER_PATH src/ && source devel/setup.bash && catkin_make

# Create a place to mount our add-ons, & install manager dependencies
ARG ADDONS_PATH
ENV BENCHBOT_ADDONS_PATH=$ADDONS_PATH
RUN mkdir -p $BENCHBOT_ADDONS_PATH && pip install pyyaml
