FROM ubuntu:latest 
MAINTAINER Jink19v@gmail.com 

# Take arguments 
ENV FREQUENCY "0 * * * *" 
ENV USER=99 
ENV GROUP=100 

# Set user and group 
RUN groupadd -r $GROUP && useradd --no-log-init -r -g $GROUP $USER

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Install dependencies 
RUN apt-get update && apt-get install -y --no-install-recommends apt-utils
RUN apt-get install wget -y
RUN apt-get install flac -y
RUN apt-get install lame -y
RUN apt-get install cron -y
RUN apt-get install sed -y

# Get flac2mp3 script 
RUN wget https://raw.githubusercontent.com/jhillyerd/flac2mp3/master/flac2mp3
RUN chmod +x flac2mp3

# Modify script
RUN sed -i 's;\<cat\>;echo "$filepath.flac"\n      &;' flac2mp3
RUN sed -e "s/      exit 1//g" -i flac2mp3

#RUN sed -i 's/\<print\>/or -name \"*.jpeg\" -or -name \"*.Jpeg\"  -or -name \"*.JPG\" -or -name \"*.png\" -&/' flac2mp3

# Mount volumes 
VOLUME /input_dir
VOLUME /output_dir

# Create run script 
RUN echo "#!/bin/bash\n\nif [[ \"`pidof -x $(basename $0) -o %PPID`\" ]]; then exit; fi\n\n/flac2mp3 /input_dir /output_dir" > /run.sh
RUN chmod +x run.sh

# Create cron job 
RUN echo "$FREQUENCY /run.sh >> /var/log/cron.log 2>&1\n" > /etc/cron.d/flac2mp3-cron 

# Give execution rights on the cron job 
RUN chmod 0644 /etc/cron.d/flac2mp3-cron

# Apply cron job 
RUN crontab /etc/cron.d/flac2mp3-cron

# Create the log file to be able to run tail 
RUN touch /var/log/cron.log

RUN sed -i 's;\<sleep\s2\>;echo "$filepath.flac" >> /output_dir/failed_list.txt\n      &;' flac2mp3

RUN cat flac2mp3

# Run the command on container startup 
CMD touch /output_dir/failed_list.txt && cron && tail -f /var/log/cron.log
