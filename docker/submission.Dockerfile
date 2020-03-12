# Extend the BenchBot Core image
FROM benchbot/core:base

# Install some requirements for BenchBot API & visualisation tools
# (BenchBot supports both python2 & python3, but python3 is preferred)
RUN apt update && apt install -y libsm6 libxext6 libxrender-dev python3 \
    python3-pip python3-tk python-pip python-tk

# Install BenchBot API
ARG BENCHBOT_API_GIT
ARG BENCHBOT_API_HASH
RUN git clone $BENCHBOT_API_GIT && pushd benchbot_api && \
    git checkout $BENCHBOT_API_HASH && pip3 install .

# Making the working directory a submission folder
WORKDIR /benchbot_submission
