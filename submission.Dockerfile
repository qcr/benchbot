# Start from the official Ubuntu image
FROM ubuntu:bionic

# Setup some bare-minimum dependencies that every submission should need
SHELL ["/bin/bash", "-c"]

ENV TZ "Etc/UTC"
RUN echo "$TZ" > /etc/timezone && \                                             
    ln -s /usr/share/zoneinfo/"$TZ" /etc/localtime && apt update && \
    apt install -y libsm6 libxext6 libxrender-dev python python-pip python-tk \
    git

ARG BENCHBOT_API_GIT
ARG BENCHBOT_API_HASH
RUN git clone $BENCHBOT_API_GIT && pushd benchbot_api && \
    git checkout $BENCHBOT_API_HASH && pip install .

# Making the working directory a submission folder
WORKDIR /benchbot_submission
