FROM ubuntu:bionic as builder

ARG GEEKBENCH_VERSION
ENV GEEKBENCH_VERSION=$GEEKBENCH_VERSION
ARG GEEKBENCH_PACKAGE
ENV GEEKBENCH_PACKAGE=$GEEKBENCH_PACKAGE

RUN test -n "$GEEKBENCH_VERSION" ; test -n "$GEEKBENCH_PACKAGE" ;

ENV DEBIAN_FRONTEND noninteractive

RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install \
        --no-install-recommends \
        --yes \
        wget \
    && rm -rf /var/lib/apt/lists/*

RUN wget --quiet --no-check-certificate http://cdn.geekbench.com/$GEEKBENCH_PACKAGE -O /tmp/$GEEKBENCH_PACKAGE \
    && mkdir -p /opt/geekbench \
    && tar xzf /tmp/$GEEKBENCH_PACKAGE -C /opt/geekbench \
    && rm -rf /tmp/$GEEKBENCH_PACKAGE


FROM ubuntu:bionic

ARG GEEKBENCH_VERSION
ENV GEEKBENCH_VERSION=$GEEKBENCH_VERSION
ARG GEEKBENCH_PACKAGE
ENV GEEKBENCH_PACKAGE=$GEEKBENCH_PACKAGE

RUN dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install \
        --no-install-recommends \
        --yes \
        golang \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/geekbench /opt/geekbench

WORKDIR /opt/geekbench/Geekbench-$GEEKBENCH_VERSION

CMD ["./geekbench5"]
