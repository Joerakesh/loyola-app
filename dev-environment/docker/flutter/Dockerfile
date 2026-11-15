FROM ghcr.io/cirruslabs/flutter:stable

ARG ANDROID_PLATFORM=android-37
ARG ANDROID_BUILD_TOOLS=36.0.0

# Keep the Android SDK paths supplied by the upstream Flutter image.
ENV PUB_CACHE=/root/.pub-cache
ENV GRADLE_USER_HOME=/root/.gradle

RUN yes | sdkmanager --licenses >/dev/null 2>&1 || true \
    && sdkmanager "${ANDROID_PLATFORM}" "build-tools;${ANDROID_BUILD_TOOLS}" \
    && flutter config --no-analytics \
    && flutter doctor -v

WORKDIR /workspace
CMD ["bash"]
