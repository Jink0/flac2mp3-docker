FROM nitincypher/docker-ubuntu-python-pip

ARG FLACSYNC_VERSION=0.3.2 
ARG NERO_AAC_CODEC_VERSION=1.5.1

# Take arguments 
ENV FREQUENCY "* * * * *" 

ENV USER=99 
ENV GROUP=100 

ENV THREAD_COUNT=4
ENV ENC_TYPE=mp3
ENV MP3_Q=2


# Set user and group 
RUN groupadd -r $GROUP && useradd --no-log-init -r -g $GROUP $USER

### Install dependencies ### 
RUN set -ex \ && deps=' \
      python-imaging \
      flac \
      vorbis-tools \
      lame \
      unzip \
      lib32stdc++6'

RUN apt-get update && apt-get install -y --no-install-recommends $deps && rm -rf /var/lib/apt/lists/*
 
### Install Python dependencies ###
RUN pip install \ 
    Pillow \ 
    mutagen
	
### Install the Nero AAC Codec binaries ###
#RUN mkdir -p /root/.local/bin

RUN apt-get update 
RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:robert-tari/main
RUN apt-get update
RUN apt-get install -y neroaac
RUN apt-get install -y curl
RUN apt-get install -y cron

### Install flacsync ###
RUN curl -O -J -L https://github.com/cmcginty/flacsync/raw/master/dist/flacsync-${FLACSYNC_VERSION}.tar.gz
RUN tar xzf flacsync-${FLACSYNC_VERSION}.tar.gz
 
### PIL is currently unmaintained, so use Pillow in its place ###
RUN cd /flacsync-${FLACSYNC_VERSION} && sed -i 's/import Image/from PIL import Image/' flacsync/encoder.py && python setup.py install --user

### Cleanup ###
RUN rm -rf flacsync-${FLACSYNC_VERSION}
RUN rm -f flacsync-${FLACSYNC_VERSION}.tar.gz
 
ENV PATH=/root/.local/bin:$PATH 

#ENTRYPOINT flacsync --threads=${THREAD_COUNT} --type=${ENC_TYPE} --copy-cover-art --mp3-quality=${MP3_Q} -d "data/out/" "data/in"

# Mount volumes 
VOLUME /data/in
VOLUME /data/out

# Create run script 
RUN echo "#!/bin/bash\n\nif [[ \"`pidof -x $(basename $0) -o %PPID`\" ]]; then exit; fi\n\nflacsync --threads=${THREAD_COUNT} --type=${ENC_TYPE} --copy-cover-art --mp3-quality=${MP3_Q} -d "data/out/" "data/in"" > /run.sh
RUN chmod +x run.sh

# Create cron job 
RUN echo "$FREQUENCY /run.sh >> /var/log/cron.log 2>&1\n" > /etc/cron.d/flacsync-cron 

# Give execution rights on the cron job 
RUN chmod 0644 /etc/cron.d/flacsync-cron

# Apply cron job 
RUN crontab /etc/cron.d/flacsync-cron

# Create the log file to be able to run tail 
RUN touch /var/log/cron.log

# Run the command on container startup 
CMD cron && tail -f /var/log/cron.log
