FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    sudo \
    git \
    curl \
    wget \
    jq \
    vim \
    nano \
    file \
    tree \
    build-essential \
    gcc \
    make \
    bear \
    perl \
    dkms \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python-is-python3 \
    zsh \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    fzf \
    ripgrep \
    fd-find \
    bat \
    xxd \
    hexedit \
    gdb \
    gdbserver \
    strace \
    ltrace \
    binutils-riscv64-unknown-elf \
    gcc-riscv64-unknown-elf \
    gdb-multiarch \
    qemu-system-misc \
    clangd \
    clang-format \
    clang-tidy \
    less \
    bsdextrautils \
  && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
  mkdir -p /opt/gef; \
  curl -fsSL https://raw.githubusercontent.com/hugsy/gef/master/gef.py -o /opt/gef/gef.py

COPY gdbinit /etc/gdb/gdbinit
COPY gdb-gef /usr/local/bin/gdb-gef
COPY gdb-multiarch-gef /usr/local/bin/gdb-multiarch-gef
COPY gef.rc /etc/skel/.gef.rc

COPY zshenv /etc/skel/.zshenv
COPY zprofile /etc/skel/.zprofile
COPY zshrc /etc/skel/.zshrc

RUN set -eux; \
  chmod +x /usr/local/bin/gdb-gef /usr/local/bin/gdb-multiarch-gef; \
  if id -u ubuntu >/dev/null 2>&1; then \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu; \
    chmod 0440 /etc/sudoers.d/ubuntu; \
    usermod -s /usr/bin/zsh ubuntu; \
  fi

RUN set -eux; \
  if id -u ubuntu >/dev/null 2>&1; then \
    cp /etc/skel/.gef.rc /home/ubuntu/.gef.rc; \
    cp /etc/skel/.zshenv /home/ubuntu/.zshenv; \
    cp /etc/skel/.zprofile /home/ubuntu/.zprofile; \
    cp /etc/skel/.zshrc /home/ubuntu/.zshrc; \
    chown ubuntu:ubuntu /home/ubuntu/.gef.rc /home/ubuntu/.zshenv /home/ubuntu/.zprofile /home/ubuntu/.zshrc; \
  fi
