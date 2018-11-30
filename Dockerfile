FROM ubuntu:latest
MAINTAINER Jink19v@gmail.com

ARG DEBIAN_FRONTEND=noninteractive

# Take arguments
ENV FREQUENCY "* * * * *"
ENV USER=99
ENV GROUP=100
ENV OPTS="--preset=V2 --processes=4 --copyfiles"

# Set user and group
RUN groupadd -r $GROUP && useradd --no-log-init -r -g $GROUP $USER

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils > /dev/null
RUN apt-get install git -y > /dev/null
RUN apt-get install cron -y > /dev/null
RUN apt-get install flac -y > /dev/null
RUN apt-get install lame -y > /dev/null

# Get flac2mp3 script
RUN git clone https://github.com/robinbowes/flac2mp3.git
RUN chmod +x flac2mp3/flac2mp3.pl

# Mount volumes
VOLUME /FLAC_dir
VOLUME /mp3_dir

# Create run script
RUN echo "#!/bin/bash\n\nif [[ \"\`pidof -x $(basename $0) -o %PPID\`\" ]]; then exit; fi\n\n/flac2mp3/flac2mp3.pl $OPTS /FLAC_dir /mp3_dir" > /run.sh
RUN chmod +x run.sh

# Create cron job
RUN echo "$FREQUENCY /run.sh >> /var/log/cron.log 2>&1\n" > /etc/cron.d/flac2mp3-cron 

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/flac2mp3-cron

# Apply cron job
RUN crontab /etc/cron.d/flac2mp3-cron

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

# Run the command on container startup
CMD cron && tail -f /var/log/cron.log
