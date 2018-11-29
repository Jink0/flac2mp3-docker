FROM ubuntu:latest
MAINTAINER Jink19v@gmail.com

ENV DEBIAN_FRONTEND noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils
RUN apt-get install wget -y > /dev/null
RUN apt-get install flac -y > /dev/null
RUN apt-get install lame -y > /dev/null
RUN apt-get install cron -y > /dev/null

# Get flac2mp3 script
RUN wget https://raw.githubusercontent.com/jhillyerd/flac2mp3/master/flac2mp3
RUN chmod +x flac2mp3

# Mount volumes
VOLUME /input_dir
VOLUME /output_dir

# Take arguments
ARG frequency="0 * * * *"

# Create run script
RUN echo "if [[ \"`pidof -x $(basename $0) -o %PPID`\" ]]; then exit; fi\n\n/flac2mp3 /input_dir /output_dir" > run.sh
RUN chmod +x run.sh

# Create cron job
RUN echo "$frequency /run.sh >> /var/log/cron.log 2>&1\n" > /etc/cron.d/flac2mp3-cron 

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/flac2mp3-cron

# Apply cron job
RUN crontab /etc/cron.d/flac2mp3-cron

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

# Run the command on container startup
CMD cron && tail -f /var/log/cron.log

