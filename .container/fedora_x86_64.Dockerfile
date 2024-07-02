# syntax=docker/dockerfile:1
# -----------------------------------------------------------------------------
# Author: Alejandro M. BERNARDIS
# Email: alejandro.bernardis at gmail.com
# -----------------------------------------------------------------------------
ARG OS=fedora:39
FROM ${OS} AS base
RUN dnf update --assumeyes

# -----------------------------------------------------------------------------
FROM base AS deps
ARG PKG_TOOLS=0
ARG NET_TOOLS=0
RUN dnf update --assumeyes
RUN dnf install --assumeyes \
      curl \
      git \
      man-db \
      neovim \
      pandoc \
      procps-ng \
      sudo \
      tmux \
      tree \
      unzip \
      zsh \
    ; \
    if [[ "${PKG_TOOLS:-0}" -eq '1' ]]; then \
      dnf install --assumeyes --allowerasing \
        gcc \
        rpm-build \
        rpm-devel \
        rpmlint \
        make \
        python \
        bash \
        coreutils \
        diffutils \
        patch \
        rpmdevtools \
      ; \
    fi \
    ; \
    if [[ "${NET_TOOLS:-0}" -eq '1' ]]; then \
      dnf install --assumeyes --allowerasing \
        dnsutils \
        iputils \
        nc \
        net-tools \
        nmap \
      ; \
    fi \
;

# -----------------------------------------------------------------------------
FROM deps AS image

ARG UID=1000

ENV OCI=1
ENV TERM=tmux-256color
ENV LANG=C.UTF-8
ENV LC_TYPE=C.UTF-8

LABEL name="alejandrobernardis/gstat"
LABEL version="1.0.0"
LABEL author="Alejandro M. BERNARDIS"
LABEL maintainer="alejandro.bernardis@gmail.com"

RUN \
  useradd \
    --uid ${UID} \
    --user-group \
    --create-home \
    --groups wheel \
    frank && \
  echo "Defaults !env_reset" |tee /etc/sudoers.d/00-ENV-RESET && \
  echo "frank ALL=(ALL:ALL) NOPASSWD: ALL" |tee /etc/sudoers.d/99-NOPASSWD \
;

WORKDIR /home/frank
COPY --chown=${UID}:0 .container/custom/entrypoint.sh /entrypoint.sh
COPY --chown=${UID}:${UID} .container/custom/home/frank/ .
RUN chmod a+x /entrypoint.sh

USER ${UID}
STOPSIGNAL SIGTERM
ENTRYPOINT ["/entrypoint.sh"]
CMD ["tmux"]
