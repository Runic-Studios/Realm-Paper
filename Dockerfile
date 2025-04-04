FROM amazoncorretto:21-alpine

WORKDIR /opt/paper

COPY server/ /opt/paper

RUN chmod +x /opt/paper/entrypoint.sh

EXPOSE 25565

ENTRYPOINT ["/opt/paper/entrypoint.sh"]
