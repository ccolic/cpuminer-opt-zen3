# cpuminer-opt optimized for AMD Ryzen 9 5950X (Zen 3)
# Enables: AVX2, AES-NI, SHA extensions
#
# Build with: docker build -t cpuminer-opt:zen3 .

FROM debian:bookworm-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    automake \
    autoconf \
    pkg-config \
    libcurl4-openssl-dev \
    libjansson-dev \
    libssl-dev \
    libgmp-dev \
    zlib1g-dev \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Clone cpuminer-opt (JayDDee's optimized version)
WORKDIR /build
RUN git clone --depth 1 https://github.com/JayDDee/cpuminer-opt.git

WORKDIR /build/cpuminer-opt

# Build with Zen 3 optimizations
# -march=znver3 enables: AVX2, AES-NI, SHA, SSE4.2, and all Zen 3 specific features
# This is critical for hardware SHA acceleration on Ryzen
RUN ./autogen.sh && \
    ./configure \
        CFLAGS="-O3 -march=znver3 -mtune=znver3" \
        CXXFLAGS="-O3 -march=znver3 -mtune=znver3" \
        --with-curl \
        --with-crypto && \
    make -j$(nproc)

# Runtime image
FROM debian:bookworm-slim

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    libcurl4 \
    libjansson4 \
    libssl3 \
    libgmp10 \
    && rm -rf /var/lib/apt/lists/*

# Copy the compiled binary
COPY --from=builder /build/cpuminer-opt/cpuminer /usr/local/bin/cpuminer

# Create non-root user for security
RUN useradd -r -s /bin/false miner
USER miner

ENTRYPOINT ["cpuminer"]
CMD ["--help"]
