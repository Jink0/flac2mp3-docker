FROM python:2 

ARG FLACSYNC_VERSION=0.3.2 
ARG NERO_AAC_CODEC_VERSION=1.5.1

ENV THREAD_COUNT=4
ENV ENC_TYPE=mp3
ENV MP3_Q=2

### Install dependencies ### 
RUN set -ex \ && deps=' \
      python-imaging \
      flac \
      vorbis-tools \
      lame \
      unzip \
      lib32stdc++6'

RUN apt-get update && apt-get install -y --no-install-recommends $deps && rm -rf /var/lib/apt/lists/* \ 
 
### Install Python dependencies ###
RUN pip install \ 
    Pillow \ 
    mutagen
	
### Install the Nero AAC Codec binaries ###
RUN mkdir -p /root/.local/bin
 
### videohelp.com has an HTTP redirect to the download file ###
RUN curl -o NeroAACCodec-${NERO_AAC_CODEC_VERSION}.zip -J -L $( \
      curl -L -s http://www.videohelp.com/download/NeroAACCodec-${NERO_AAC_CODEC_VERSION}.zip \ 
      | grep -i HTTP-EQUIV=\"Refresh \
      | grep -o http:[^\"]* \
    )
    
RUN unzip -j -d /root/.local/bin NeroAACCodec-${NERO_AAC_CODEC_VERSION}.zip linux/* \
 && chmod -R u+x /root/.local/bin \
 && rm -f NeroAACCodec-${NERO_AAC_CODEC_VERSION}.zip
 
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
