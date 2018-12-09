FROM ubuntu:14.10

ARG FLACSYNC_VERSION=0.3.2 
ARG NERO_AAC_CODEC_VERSION=1.5.1

ENV THREAD_COUNT=4
ENV ENC_TYPE=mp3
ENV MP3_Q=2

### Instal python ###
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
    build-essential \
    ca-certificates \
    gcc \
    git \
    libpq-dev \
    make \
    python-pip \
    python2.7 \
    python2.7-dev \
    ssh \
    && apt-get autoremove \
    && apt-get clean

RUN pip install -U "setuptools==3.4.1"
RUN pip install -U "pip==1.5.4"
RUN pip install -U "Mercurial==2.9.1"
RUN pip install -U "virtualenv==1.11.4"

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
 
RUN apt-get install software-properties-common
RUN add-apt-repository -y ppa:robert-tari/main
RUN apt-get update
RUN apt-get install -y neroaac

### Install flacsync ###
RUN curl -O -J -L https://github.com/cmcginty/flacsync/raw/master/dist/flacsync-${FLACSYNC_VERSION}.tar.gz \
 && tar xzf flacsync-${FLACSYNC_VERSION}.tar.gz \
 && cd flacsync-${FLACSYNC_VERSION}
 
### PIL is currently unmaintained, so use Pillow in its place ###
RUN sed -i 's/import Image/from PIL import Image/' flacsync/encoder.py \
 && python setup.py install --user \
 && cd - \
 && rm -rf flacsync-${FLACSYNC_VERSION} \
 && rm -f flacsync-${FLACSYNC_VERSION}.tar.gz
 
ENV PATH=/root/.local/bin:$PATH 
ENTRYPOINT ["flacsync", "--threads=THREAD_COUNT", "--type=ENC_TYPE", "--copy-cover-art", "--mp3-quality=MP3_Q", "-d", "data/out/", "data/in"]
