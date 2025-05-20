FROM alpine:3.18

# Needed by entrypoint
RUN apk add --no-cache curl unzip \
  && curl -Lo /usr/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
  && chmod +x /usr/bin/yq

# JBR
ENV JBR_VERSION=21.0.7-b992.24
ENV JBR_TAR=jbr-${JBR_VERSION}-linux-musl-x64.tar.gz
ENV JBR_URL=https://cache-redirector.jetbrains.com/intellij-jbr/${JBR_TAR}

WORKDIR /opt

RUN curl -fsSL "${JBR_URL}" -o /tmp/${JBR_TAR} && \
    tar -xzf /tmp/${JBR_TAR} -C /opt && \
    ln -s /opt/jbr-* /opt/jbr && \
    rm /tmp/${JBR_TAR}

ENV JAVA_HOME=/opt/jbr
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# HotSwap
ENV HOTSWAP_AGENT_VERSION=2.0.1
RUN mkdir -p ${JAVA_HOME}/lib/hotswap && \
    curl -fsSL -o ${JAVA_HOME}/lib/hotswap/hotswap-agent.jar \
    https://github.com/HotswapProjects/HotswapAgent/releases/download/RELEASE-${HOTSWAP_AGENT_VERSION}/hotswap-agent-${HOTSWAP_AGENT_VERSION}.jar


# Copy Application
WORKDIR /opt/paper
COPY server/ /opt/paper

RUN chmod +x /opt/paper/palimpsest && \
    chmod +x /opt/paper/entrypoint.sh

EXPOSE 25565

ENTRYPOINT ["/opt/paper/entrypoint.sh"]
