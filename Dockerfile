FROM ubuntu:24.04 AS builder

ARG GEEKBENCH_VERSION
ENV GEEKBENCH_VERSION=$GEEKBENCH_VERSION
ARG GEEKBENCH_PACKAGE
ENV GEEKBENCH_PACKAGE=$GEEKBENCH_PACKAGE

RUN test -n "$GEEKBENCH_VERSION" ; test -n "$GEEKBENCH_PACKAGE" ;

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install \
        --no-install-recommends \
        --yes \
        wget
RUN rm -rf /var/lib/apt/lists/*

RUN wget --quiet --no-check-certificate http://cdn.geekbench.com/$GEEKBENCH_PACKAGE -O /tmp/$GEEKBENCH_PACKAGE \
    && mkdir -p /opt/geekbench \
    && tar xzf /tmp/$GEEKBENCH_PACKAGE -C /opt/geekbench \
    && rm -rf /tmp/$GEEKBENCH_PACKAGE


FROM ubuntu:24.04

ARG GEEKBENCH_VERSION
ENV GEEKBENCH_VERSION=$GEEKBENCH_VERSION

COPY --from=builder /opt/geekbench /opt/geekbench

WORKDIR /opt/geekbench/Geekbench-$GEEKBENCH_VERSION

CMD ["./geekbench6"]
