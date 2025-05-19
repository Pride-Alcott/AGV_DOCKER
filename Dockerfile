FROM ros:humble-perception

# Environment
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV UDEV=on
ENV PYTHONPATH=\$PYTHONPATH:/usr/local/lib/python3.10/dist-packages

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3-pip python3-dev \
    git wget curl vim \
    build-essential cmake \
    lsb-release gnupg2 \
    udev libudev-dev libusb-1.0-0-dev \
    v4l-utils libv4l-dev \
    python3-serial \
    ros-humble-mavros \
    ros-humble-mavros-extras \
    ros-humble-mavros-msgs \
  && rm -rf /var/lib/apt/lists/*

# Install GeographicLib datasets
RUN wget https://raw.githubusercontent.com/mavlink/mavros/master/mavros/scripts/install_geographiclib_datasets.sh \
    && chmod +x install_geographiclib_datasets.sh \
    && ./install_geographiclib_datasets.sh \
    && rm install_geographiclib_datasets.sh

# Python vision & serial
RUN pip3 install --no-cache-dir \
    ultralytics \
    numpy \
    opencv-python \
    matplotlib \
    torch torchvision torchaudio \
    pyserial

# Create and populate workspace
WORKDIR /AGV
RUN mkdir -p src
RUN git clone https://github.com/Pride-Alcott/Solar-farm-AGV.git src/Solar-farm-AGV

# Build the ROS 2 workspace
RUN bash -c "source /opt/ros/humble/setup.bash && cd /AGV && colcon build"

# Auto-source ROS & workspace
RUN echo 'source /opt/ros/humble/setup.bash' >> /root/.bashrc && \
    echo 'source /AGV/install/setup.bash' >> /root/.bashrc

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
