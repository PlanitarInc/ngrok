FROM scratch

ADD bin/docker/ngrok /ngrok
ADD bin/docker/ngrokd /ngrokd

ENV PATH /

CMD ["ngrok"]
