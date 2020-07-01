ARG ARCH=
ARG CUDA=10.1
FROM nvidia/cuda:${CUDA}-base-ubuntu18.04 as base
# ARCH and CUDA are specified again because the FROM directive resets ARGs
# (but their default value is retained if set previously)
ARG ARCH
ARG CUDA
ARG CUDNN=7.6.4.38-1
ARG CUDNN_MAJOR_VERSION=7
ARG LIB_DIR_PREFIX=x86_64
ARG LIBNVINFER=6.0.1-1
ARG LIBNVINFER_MAJOR_VERSION=6

ARG BUILD_TAG
ENV BUILD_TAG ${BUILD_TAG}

# Needed for string substitution
SHELL ["/bin/bash", "-c"]
# Pick up some TF dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cuda-command-line-tools-${CUDA/./-} \
        # There appears to be a regression in libcublas10=10.2.2.89-1 which
        # prevents cublas from initializing in TF. See
        # https://github.com/tensorflow/tensorflow/issues/9489#issuecomment-562394257
        libcublas10=10.2.1.243-1 \ 
        cuda-nvrtc-${CUDA/./-} \
        cuda-cufft-${CUDA/./-} \
        cuda-curand-${CUDA/./-} \
        cuda-cusolver-${CUDA/./-} \
        cuda-cusparse-${CUDA/./-} \
        curl \
        libcudnn7=${CUDNN}+cuda${CUDA} \
        libfreetype6-dev \
        libhdf5-serial-dev \
        libzmq3-dev \
        libglfw3-dev \
        libglfw3 \
        pkg-config \
        software-properties-common

# Install TensorRT if not building for PowerPC
RUN [[ "${ARCH}" = "ppc64le" ]] || { apt-get update && \
        apt-get install -y --no-install-recommends libnvinfer${LIBNVINFER_MAJOR_VERSION}=${LIBNVINFER}+cuda${CUDA} \
        libnvinfer-plugin${LIBNVINFER_MAJOR_VERSION}=${LIBNVINFER}+cuda${CUDA} \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*; }

# For CUDA profiling, TensorFlow requires CUPTI.
ENV LD_LIBRARY_PATH /usr/local/cuda/extras/CUPTI/lib64:/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Link the libcuda stub to the location where tensorflow is searching for it and reconfigure
# dynamic linker run-time bindings
RUN ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/stubs/libcuda.so.1 \
    && echo "/usr/local/cuda/lib64/stubs" > /etc/ld.so.conf.d/z-cuda-stubs.conf \
    && ldconfig

# See http://bugs.python.org/issue19846
ENV LANG C.UTF-8

# Update
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    ssh \
    vim \
    emacs \
    tmux \
    swig \
    cmake \
    rsync \
    libprotobuf-dev \
    protobuf-compiler \
    ca-certificates \
    wget \
    libgtk2.0-0 \
    libatlas-base-dev \
    libboost-all-dev \
    libgflags-dev \
    libgoogle-glog-dev \
    libprotobuf-dev \
    ffmpeg \
    sshfs \
    unzip \
    zip \
    net-tools \
    libopenexr-dev \
    libsm6 libxext6 libxrender-dev

# youtube-dl for downloading realestate10k
RUN wget https://yt-dl.org/downloads/latest/youtube-dl -O /usr/local/bin/youtube-dl && \
    chmod a+rx /usr/local/bin/youtube-dl

# python distribution
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/conda && rm ~/anaconda.sh && chmod 777 -R /opt/conda

ENV PATH="/usr/local/bin:/opt/conda/bin:${PATH}"

# RUN source /root/.bashrc
RUN conda update --yes conda

RUN conda install -y cython scikit-image ipython h5py nose pandas protobuf pyyaml jupyter
RUN conda install -y pytorch=1.4 torchvision cudatoolkit=10.1 -c pytorch
RUN conda install -y -c conda-forge -c fvcore fvcore
RUN conda install -c pytorch3d-nightly pytorch3d

RUN pip install opencv-python tensorflow-gpu==2.2 tensorflow-probability tf_slim
RUN pip install --upgrade tensorflow-graphics-gpu tensorflow-addons OpenEXR
RUN pip install tqdm tensorboardX


WORKDIR /workspace
