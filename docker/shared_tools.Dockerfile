# Note: this Dockerfile is not meant to be used in isolation. It is used to add
# BenchBot's shared tools like ROS packages and addons to an existing Docker
# image

# Ensure our benchbot directory exists
ENV BENCHBOT_DIR="/benchbot"
RUN mkdir -p $BENCHBOT_DIR

# Install ROS Noetic
RUN apt update && apt install -y curl && \
    echo "deb http://packages.ros.org/ros/ubuntu focal main" > \
    /etc/apt/sources.list.d/ros-latest.list && \
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | \
    apt-key add - && apt update && \
    apt install -y ros-noetic-ros-base python3-rosdep \
    python3-rosinstall python3-rosinstall-generator python3-wstool \
    python3-catkin-tools python3-pip build-essential \
    ros-noetic-tf2-ros ros-noetic-tf

# Build a ROS Catkin workspace
ENV ROS_WS_PATH="$BENCHBOT_DIR/ros_ws"
RUN rosdep init && rosdep update && mkdir -p $ROS_WS_PATH/src && \
    source /opt/ros/noetic/setup.bash && \
    pushd $ROS_WS_PATH && catkin_make && source devel/setup.bash && popd 

# Add BenchBot's common ROS packages
ARG BENCHBOT_MSGS_GIT
ARG BENCHBOT_MSGS_HASH
ENV BENCHBOT_MSGS_PATH="$BENCHBOT_DIR/benchbot_msgs"
RUN git clone $BENCHBOT_MSGS_GIT $BENCHBOT_MSGS_PATH && \
    pushd $BENCHBOT_MSGS_PATH && git checkout $BENCHBOT_MSGS_HASH && \
    pip install -r requirements.txt && pushd $ROS_WS_PATH && \
    ln -sv $BENCHBOT_MSGS_PATH src/ && source devel/setup.bash && catkin_make

ARG BENCHBOT_CONTROLLER_GIT
ARG BENCHBOT_CONTROLLER_HASH
ENV BENCHBOT_CONTROLLER_PATH="$BENCHBOT_DIR/benchbot_robot_controller"
RUN git clone $BENCHBOT_CONTROLLER_GIT $BENCHBOT_CONTROLLER_PATH && \
    pushd $BENCHBOT_CONTROLLER_PATH && git checkout $BENCHBOT_CONTROLLER_HASH && \
    pip install -r requirements.txt && \
    sed -i 's/np.float/float/g' /usr/local/lib/python3.8/dist-packages/transforms3d/quaternions.py && \ 
    pushd $ROS_WS_PATH && \
    pushd src && git clone https://github.com/eric-wieser/ros_numpy && \
    sed -i 's/np.float/float/g' /benchbot/ros_ws/src/ros_numpy/src/ros_numpy/point_cloud2.py && \
    popd && \
    ln -sv $BENCHBOT_CONTROLLER_PATH src/ && source devel/setup.bash && catkin_make

# Create a place to mount our add-ons, & install manager dependencies
ARG BENCHBOT_ADDONS_PATH
ENV BENCHBOT_ADDONS_PATH="$BENCHBOT_ADDONS_PATH"
RUN apt update && apt install -y python3 python3-pip && \
    python3 -m pip install --upgrade pip setuptools wheel pyyaml && \
    mkdir -p $BENCHBOT_ADDONS_PATH
