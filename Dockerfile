FROM nvidia/cuda:8.0-devel-ubuntu16.04

RUN apt-get update \
 && apt-get install --yes --no-install-recommends \
    python nano \
 && rm -rf /var/lib/apt/lists/*

# Copy SnuCL-TR files inside
WORKDIR /snucl-tr
COPY snucl-tr-0.8b.tar.gz ./
RUN echo "5a210c6f2a9ec9210fcf7f3d89aef918570e6dbb2364fab81a6d08b7e2dc726f  snucl-tr-0.8b.tar.gz" | sha256sum -c \
 && tar xf snucl-tr-0.8b.tar.gz

# Define environment variables necessary for the CUDA2OpenCL Makefiles
ENV CUDA_DIR "/usr/local/cuda"
ENV OPENCL_TO_CUDA_DIR="/snucl-tr/opencl2cuda"

# Build modified opencl2cuda LLVM
RUN cd opencl2cuda/build \
 && ../llvm.mod/configure --enable-optimized CC=gcc CXX=g++ BUILD_EXAMPLES=1 \
 # Compilation fails sometimes (probably race conditions with parallelism),
 # as a workaround to avoid long compile times, retry on error
 && (make -j"$(nproc)" || make -j"$(nproc)" || make -j"$(nproc)")

# Build common
RUN cd opencl2cuda/common/common/ \
 && (make -j"$(nproc)" || make -j"$(nproc)" || make -j"$(nproc)")

# Add environment
RUN export OPENCL_TO_CUDA=/snucl-tr/opencl2cuda/opencl2cuda \
 && export OPENCL_TO_CUDA_GPU_ARCH=compute_30 \

