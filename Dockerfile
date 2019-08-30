# Use an official Python runtime as a parent image
FROM ubuntu:bionic

# Configurable settings for the docker image
ENV TZ 'Etc/UTC'
ENV NVIDIA_DRIVER nvidia-driver-430

# Set the working directory, & use bash as the shell
WORKDIR /home/benchbot
SHELL ["/bin/bash", "-c"]

# Configure some basics to get us up & running
RUN echo "$TZ" > /etc/timezone && \
    ln -s /usr/share/zoneinfo/"$TZ" /etc/localtime && \
    apt update && apt -yq install gnupg2 tzdata software-properties-common

# Install ROS Melodic
# TODO: look at trimming this down later
# RUN echo "deb http://packages.ros.org/ros/ubuntu bionic main" > /etc/apt/sources.list.d/ros-latest.list 
# RUN apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
# RUN apt update && \
#     apt install -y ros-melodic-desktop-full
# RUN mkdir -p ros_ws/src && \
#     source /opt/ros/melodic/setup.bash && pushd ros_ws && catkin_make && source devel/setup.bash && popd

# # Install Isaac (using local copy)
COPY isaac_sdk isaac_sdk
RUN ./isaac_sdk/engine/build/scripts/install_dependencies.sh
RUN add-apt-repository ppa:graphics-drivers/ppa && \
    apt update && DEBIAN_FRONTEND=noninteractive apt install -yq "$NVIDIA_DRIVER"


# # Install BenchBot software (via git repos)
# RUN pushd ros_ws && pushd src && \
#     git clone git@bitbucket.org:acrv/benchbot_supervisor && \
#     git clone git@bitbucket.org:acrv/benchbot_simulator_retired && \
#     popd && catkin_make
# # TODO

# # Install any remaining dependencies
# # TODO
