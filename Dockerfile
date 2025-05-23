FROM --platform=linux/arm64 ros:humble-perception

# Environment
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV UDEV=on
ENV PYTHONPATH=$PYTHONPATH:/usr/local/lib/python3.10/dist-packages
ENV HOME=/AGV

# Create AGV directory and set as home
RUN mkdir -p /AGV
WORKDIR /AGV

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

# Install Python packages - YOLOv8s optimized for Pi + your requested packages
RUN pip3 install --no-cache-dir \
    ultralytics \
    numpy==1.24.4 \
    opencv-python \
    matplotlib \
    pyserial \
    pymavlink \
    piexif \
    --extra-index-url https://download.pytorch.org/whl/cpu \
    torch torchvision torchaudio

# Create src directory and clone repository
RUN mkdir -p src
RUN cd src && git clone https://github.com/Pride-Alcott/AGV.git

# Build the ROS 2 workspace with limited parallelism for Pi
RUN bash -c "source /opt/ros/humble/setup.bash && colcon build --parallel-workers 2"

# Create .bashrc in /AGV and auto-source ROS & workspace
RUN echo 'source /opt/ros/humble/setup.bash' > /AGV/.bashrc && \
    echo 'source /AGV/install/setup.bash' >> /AGV/.bashrc

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set entrypoint and default command
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
