ARG APP_NAME=iot_stream
ARG USERNAME=iot_stream
ARG IMAGE_WS_DIR=/home/${USERNAME}/workspace


FROM debian:bookworm-slim AS base
ARG USERNAME
ARG IMAGE_WS_DIR


RUN apt clean
RUN apt update && apt install -y \
  cmake \
  m4 \
  curl \
  pkg-config \
  libssl-dev \
  libcurl4-openssl-dev \
  liblog4cplus-dev \
  libgstreamer1.0-dev \
  libgstreamer-plugins-base1.0-dev \
  gstreamer1.0-plugins-base-apps \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-ugly \
  gstreamer1.0-tools \
  git \
  gcc \
  build-essential \
  sudo \
  wget 

RUN ARCH=$(uname -m) && \
  if [ "$ARCH" = "x86_64" ]; then \
  YQ_BINARY="yq_linux_amd64"; \
  elif [ "$ARCH" = "aarch64" ]; then \
  YQ_BINARY="yq_linux_arm64"; \
  else \
  echo "Unsupported architecture: $ARCH"; \
  exit 1; \
  fi && \
  wget "https://github.com/mikefarah/yq/releases/latest/download/${YQ_BINARY}" -O /usr/bin/yq && \
  chmod +x /usr/bin/yq

RUN groupadd $USERNAME && \
  useradd -ms /bin/bash -g $USERNAME $USERNAME && \
  sh -c 'echo "$USERNAME ALL=(root) NOPASSWD:ALL" >> /etc/sudoers'

USER $USERNAME
WORKDIR /home/$USERNAME

RUN mkdir -p $IMAGE_WS_DIR

FROM base AS build
ARG APP_NAME
ARG USERNAME
ARG IMAGE_WS_DIR

# Build the app
WORKDIR $IMAGE_WS_DIR

COPY --chown=$USERNAME:$USERNAME include include
COPY --chown=$USERNAME:$USERNAME src src
COPY --chown=$USERNAME:$USERNAME CMakeLists.txt CMakeLists.txt

RUN mkdir -p build && \
  cd build && \
  cmake .. -DCMAKE_BUILD_TYPE=Release && \
  make -j$(nproc)

RUN mv build/$APP_NAME $IMAGE_WS_DIR

FROM base AS final
ARG APP_NAME
ARG USERNAME
ARG IMAGE_WS_DIR

USER $USERNAME

WORKDIR /

COPY --from=build --chown=$USERNAME:$USERNAME $IMAGE_WS_DIR/$APP_NAME .

ENV THING_CERT_DEST_PATH=$IMAGE_WS_DIR/certs

RUN mkdir -p $THING_CERT_DEST_PATH
RUN curl -o $THING_CERT_DEST_PATH/AmazonRootCA1.pem https://www.amazontrust.com/repository/AmazonRootCA1.pem

COPY run.sh /run.sh
RUN sudo chmod +x /run.sh && \
  sudo chown -R $USERNAME /run.sh

COPY entrypoint.sh /entrypoint.sh
RUN sudo chmod +x /entrypoint.sh && \
  sudo chown -R $USERNAME /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]