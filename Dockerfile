FROM amazoncorretto:21-alpine

# Needed by entrypoint
RUN apk add --no-cache curl \
  && curl -Lo /usr/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
  && chmod +x /usr/bin/yq

WORKDIR /opt/paper

COPY server/ /opt/paper

RUN chmod +x /opt/paper/palimpsest &&  \
    chmod +x /opt/paper/entrypoint.sh

EXPOSE 25565

ENTRYPOINT ["/opt/paper/entrypoint.sh"]
