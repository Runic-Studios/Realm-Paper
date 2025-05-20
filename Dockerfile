FROM alpine:3.18

# Needed by entrypoint
RUN apk add --no-cache curl unzip \
  && curl -Lo /usr/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
  && chmod +x /usr/bin/yq

# JBR
ENV JBR_TAG=jbrsdk-21.0.7-linux-musl-x64-b992.24
ENV JBR_URL=https://cache-redirector.jetbrains.com/intellij-jbr/${JBR_TAG}.tar.gz

WORKDIR /opt

RUN curl -fsSL "${JBR_URL}" -o /tmp/${JBR_TAG} && \
    tar -xzf /tmp/${JBR_TAG} -C /opt && \
    ln -s /opt/jbr-* /opt/jbr && \
    rm /tmp/${JBR_TAG}

ENV JAVA_HOME=/opt/jbr
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# HotSwap
ENV HOTSWAP_AGENT_VERSION=2.0.1
RUN HOTSWAP_DIR=$(readlink -f /opt/jbr)/lib/hotswap && \
    mkdir -p "$HOTSWAP_DIR" && \
    curl -fsSL -o "$HOTSWAP_DIR/hotswap-agent.jar" \
    https://github.com/HotswapProjects/HotswapAgent/releases/download/RELEASE-${HOTSWAP_AGENT_VERSION}/hotswap-agent-${HOTSWAP_AGENT_VERSION}.jar

# Copy Application
WORKDIR /opt/paper
COPY server/ /opt/paper

RUN chmod +x /opt/paper/palimpsest && \
    chmod +x /opt/paper/entrypoint.sh

EXPOSE 25565

ENTRYPOINT ["/opt/paper/entrypoint.sh"]
