# MIT License

# Copyright (c) 2020 Hongrui Zheng

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

ARG ROS_DISTRO=jazzy
FROM ros:${ROS_DISTRO}

ARG ROS_DISTRO

SHELL ["/bin/bash", "-c"]

# NVIDIA runtime defaults. Actual GPU device injection still requires running
# the container with `--gpus all`, Docker Compose `gpus: all`, or rocker
# `--nvidia` on a host with NVIDIA Container Toolkit installed.
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute

# dependencies
RUN apt-get update --fix-missing && \
    apt-get install -y git \
                       vim \
                       python3-pip \
                       libeigen3-dev \
                       mesa-utils \
                       tmux \
                       ros-${ROS_DISTRO}-rviz2
RUN apt-get -y dist-upgrade
RUN pip3 install --break-system-packages transforms3d

# f1tenth gym
RUN mkdir -p /opt/f1tenth_gym_jl
COPY pyproject.toml /opt/f1tenth_gym_jl/
COPY gym /opt/f1tenth_gym_jl/gym
COPY controllers /opt/f1tenth_gym_jl/controllers
COPY models /opt/f1tenth_gym_jl/models
COPY utils /opt/f1tenth_gym_jl/utils
RUN pip3 install --break-system-packages -e /opt/f1tenth_gym_jl

# ros2 gym bridge
RUN mkdir -p sim_ws/src/f1tenth_gym_ros
COPY thirdparty/f1tenth_gym_ros /sim_ws/src/f1tenth_gym_ros
RUN source "/opt/ros/${ROS_DISTRO}/setup.bash" && \
    cd sim_ws/ && \
    apt-get update --fix-missing && \
    rosdep install -i --from-path src --rosdistro "${ROS_DISTRO}" -y && \
    colcon build

WORKDIR '/sim_ws'
ENTRYPOINT ["/bin/bash"]
