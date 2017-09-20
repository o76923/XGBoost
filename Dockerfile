FROM nvidia/cuda:8.0-devel-ubuntu14.04
MAINTAINER James Endicott <james.endicott@colorado.edu>
WORKDIR /app
ENTRYPOINT ["/bin/bash", "-c", "source /app/sh/entrypoint.sh"]

ENV CUDA_ROOT=/usr/local/cuda \
    PYTHONPATH=/opt/intel/intelpython3/bin \
    PATH=$PATH:/opt/intel/intelpython3/bin \
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/intel/intelpython3/lib

RUN apt-get update \
    && apt-get install -y \
        apt-transport-https \
        wget \
        git \
        libopenmpi-dev \
    && wget https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB \
    && apt-key add GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB \
    && wget https://apt.repos.intel.com/setup/intelproducts.list -O /etc/apt/sources.list.d/intelproducts.list \
    && wget https://cmake.org/files/v3.8/cmake-3.8.2.tar.gz \
    && tar -xzf cmake-3.8.2.tar.gz \
    && cd cmake-3.8.2 \
    && ./bootstrap \
    && make -j19 \
    && make install \
    && apt-get update \
    && apt-get install -y \
        intelpython3 \
    && $PYTHONPATH/pip install -I \
        joblib \
        numpy \
        scikit-learn \
        pandas \
    && rm -rf /var/lib/apt/lists/*

COPY config/ /app/config/

RUN git clone --recursive https://github.com/dmlc/xgboost \
    && mv config/config.mk xgboost/dmlc-core/ \
    && cd /app/xgboost/dmlc-core/ \
    && make -j19 / \
    && cd /app/xgboost/nccl/ \
    && make -j19 \
    && make install \
    && cd /app/xgboost/rabit/ \
    && make -j19 \
    && cd /app/xgboost/ \
    && mkdir build \
    && cd build \
    && CC=mpicc cmake .. -DPLUGIN_UPDATER_GPU=ON \
    && make -j19 \
    && cd /app/xgboost/python-package \
    && python setup.py install