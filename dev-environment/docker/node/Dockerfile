FROM node:24-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates bash \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --shell /bin/bash dev

USER dev
WORKDIR /workspace
CMD ["bash"]
