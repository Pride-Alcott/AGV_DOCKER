FROM --platform=linux/arm64 ros:humble-perception

# Environment
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV UDEV=on
ENV PYTHONPATH=$PYTHONPATH:/usr/local/lib/python3.10/dist-packages

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

# Install GeographicLib datasets for MAVROS
RUN wget https://raw.githubusercontent.com/mavlink/mavros/master/mavros/scripts/install_geographiclib_datasets.sh \
    && chmod +x install_geographiclib_datasets.sh \
    && ./install_geographiclib_datasets.sh \
    && rm install_geographiclib_datasets.sh

# Install Python packages - YOLOv8s optimized for Pi
RUN pip3 install --no-cache-dir \
    ultralytics \
    numpy \
    opencv-python \
    matplotlib \
    pyserial \
    --extra-index-url https://download.pytorch.org/whl/cpu \
    torch torchvision torchaudio

# Create and populate workspace
WORKDIR /AGV
RUN mkdir -p src
RUN git clone https://github.com/Pride-Alcott/AGV.git

# Build the ROS 2 workspace with limited parallelism for Pi
RUN bash -c "source /opt/ros/humble/setup.bash && cd /AGV && colcon build --parallel-workers 2"

# Auto-source ROS & workspace
RUN echo 'source /opt/ros/humble/setup.bash' >> /root/.bashrc && \
    echo 'source /AGV/install/setup.bash' >> /root/.bashrc

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
