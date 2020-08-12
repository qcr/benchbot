# Extend the BenchBot Core image
FROM benchbot/core:base

# Install some requirements for BenchBot API & visualisation tools
# (BenchBot supports both python2 & python3, but python3 is preferred)
RUN apt update && apt install -y libsm6 libxext6 libxrender-dev python3 \
    python3-pip python3-tk python-pip python-tk

# Upgrade to latest pip (OpenCV fails to install because the pip installed by
# Ubuntu is so old). See following issues for details:
#     https://github.com/skvark/opencv-python/issues/372 
# We upgrade pip here the lazy way which will give a warning (having a recent
# version of pip without requiring Ubuntu to push it out... Ubuntu has v9 in
# apt & pip is up to v20 atm... is apparently impossible without virtual
# environments or manually deleting system files). See issue below for details:
#     https://github.com/pypa/pip/issues/5599
# I'll move on rather than digressing into how stupid it is that that's the
# state of things...
RUN pip3 install --upgrade pip

# Install BenchBot API
ARG BENCHBOT_API_GIT
ARG BENCHBOT_API_HASH
RUN git clone $BENCHBOT_API_GIT && pushd benchbot_api && \
    git checkout $BENCHBOT_API_HASH && pip3 install .

# Making the working directory a submission folder
WORKDIR /benchbot_submission
