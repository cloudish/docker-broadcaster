FROM anthonykgross/docker-base:latest

RUN echo "deb http://www.debian.org/debian jessie-backports main" >> /etc/apt/sources.list && \
    apt-get update -y && \
	apt-get upgrade -y && \
	apt-get update -y && \
	apt-get install -y jq && \
	apt-get install -y supervisor wget && \
    apt-get install -y git gcc make libpcre3-dev libssl-dev ffmpeg && \
    rm -rf /var/lib/apt/lists/* && apt-get autoremove -y --purge

ENV YOUR_IP YOUR_IP
ENV PRIVATE_KEY changethispassword
ENV STREAM_SPECIFIER hd720
ENV URL_TRANSCODE transcode
ENV URL_LIVE live
ENV EXPIRATION_TOKEN 31536000
ENV TRANSCODE_SERVERS_JSON "[{"url":"rtmp://live-ord.twitch.tv/app", "key":"insert_key_here"},{"url":"rtmp://ingest-wdc.mixer.com:1935/beam","key":"insert-key-here"}]"
ENV PASSTHROUGH_SERVERS_JSON "[{"url":"rtmp://a.rtmp.youtube.com/live2", "key":"insert_key_here"}]"
ENV FPS 60
ENV KEY_INTERVAL 120
ENV BITRATE 3500
ENV X264_PRESET veryfast
ENV CHUNK_SIZE 4096

RUN mkdir -p /conf && \
    mkdir -p /log && \
    chmod 777 /log -Rf  && \
    mkdir nginx && \
	cd nginx && \
	git clone https://github.com/arut/nginx-rtmp-module && \
	wget http://nginx.org/download/nginx-1.12.0.tar.gz && \
	tar zxpvf nginx-1.12.0.tar.gz && \
	cd nginx-1.12.0 && \
	./configure --add-module=/src/nginx/nginx-rtmp-module --with-http_ssl_module --with-http_secure_link_module --prefix=/usr/local/nginx-streaming && \
    make && \
	make install && \
	rm /src/* -Rf

ADD ./conf /conf
ADD entrypoint.sh /entrypoint.sh

RUN cp /conf/nginx/nginx.conf /usr/local/nginx-streaming/conf/nginx.conf -f  && \
    cp /conf/supervisor/conf.d/supervisor.conf /etc/supervisor/conf.d/supervisor.conf -f && \
    chmod +x /entrypoint.sh

EXPOSE 80
EXPOSE 1935

ENTRYPOINT ["/entrypoint.sh"]
CMD ["run"]