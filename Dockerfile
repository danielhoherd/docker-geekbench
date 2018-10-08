FROM ubuntu:bionic

ENV DEBIAN_FRONTEND noninteractive

RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install \
        --no-install-recommends \
        --yes \
        wget \
        golang \
    && rm -rf /var/lib/apt/lists/*

ENV GEEKBENCHVERSION Geekbench-4.3.0-Linux
ENV GEEKBENCHPACKAGE $GEEKBENCHVERSION.tar.gz

RUN wget --quiet --no-check-certificate http://cdn.geekbench.com/$GEEKBENCHPACKAGE -O /tmp/$GEEKBENCHPACKAGE \
    && mkdir -p /opt/geekbench \
    && tar xzf /tmp/$GEEKBENCHPACKAGE -C /opt/geekbench \
    && rm -rf /tmp/$GEEKBENCHPACKAGE

WORKDIR /opt/geekbench/$GEEKBENCHVERSION

CMD ["./geekbench4"]
