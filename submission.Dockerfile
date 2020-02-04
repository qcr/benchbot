# Start from the official Ubuntu image
FROM ubuntu:bionic

# Setup some bare-minimum dependencies that every submission should need
ENV TZ "Etc/UTC"
RUN echo "$TZ" > /etc/timezone && \                                             
    ln -s /usr/share/zoneinfo/"$TZ" /etc/localtime && apt update && \
    apt install -y libsm6 libxext6 libxrender-dev python python-pip python-tk \
    git

RUN git clone https://bitbucket.org/acrv/benchbot_api && cd benchbot_api && \
    pip install .

# Making the working directory a submission folder
WORKDIR /benchbot_submission
