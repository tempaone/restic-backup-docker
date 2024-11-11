# Base image setup
FROM alpine:latest as rclone

# Define target architecture
ARG TARGETARCH

# Get the correct rclone executable based on architecture
RUN case "$TARGETARCH" in \
      "amd64") RCLONE_URL="https://downloads.rclone.org/rclone-current-linux-amd64.zip" ;; \
      "arm64") RCLONE_URL="https://downloads.rclone.org/rclone-current-linux-arm64.zip" ;; \
      "arm")   RCLONE_URL="https://downloads.rclone.org/rclone-current-linux-arm.zip" ;; \
      *) echo "Unsupported architecture: $TARGETARCH" && exit 1 ;; \
    esac && \
    curl -O $RCLONE_URL && \
    unzip rclone-current-linux-*.zip && \
    mv rclone-*-linux-*/rclone /bin/rclone && \
    chmod +x /bin/rclone

# Start from restic image for final build
FROM restic/restic:0.16.0

RUN apk add --update --no-cache curl mailx

# Copy rclone executable from the build stage
COPY --from=rclone /bin/rclone /bin/rclone

# Additional setup
RUN \
    mkdir -p /mnt/restic /var/spool/cron/crontabs /var/log; \
    touch /var/log/cron.log;

# Environment variables
# ... (rest of the ENV variables remain unchanged)

# openshift fix (kept as it is)
RUN mkdir /.cache && \
    chgrp -R 0 /.cache && \
    chmod -R g=u /.cache && \
    chgrp -R 0 /mnt && \
    chmod -R g=u /mnt && \
    chgrp -R 0 /var/spool/cron/crontabs/root && \
    chmod -R g=u /var/spool/cron/crontabs/root && \
    chgrp -R 0 /var/log/cron.log && \
    chmod -R g=u /var/log/cron.log

# Volume and scripts
VOLUME /data

COPY backup.sh /bin/backup
COPY check.sh /bin/check
COPY entry.sh /entry.sh

ENTRYPOINT ["/entry.sh"]
CMD ["tail","-fn0","/var/log/cron.log"]
