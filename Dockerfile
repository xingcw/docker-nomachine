FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get install -y aptitude && aptitude dist-upgrade --purge-unused -y && aptitude clean
RUN apt-get update && apt-get install -y software-properties-common python3-software-properties sudo

# install useful system apps
RUN apt-get install -y nano htop vim xterm ssh openssh-server curl wget git mc 

# install Open JDK 8 and 9
RUN apt-get install -y openjdk-8-jdk # openjdk-9-jdk 

RUN apt-get install -y software-properties-common

RUN add-apt-repository universe

RUN apt-get update -y && apt-get install -y locales && \
  localedef --force --inputfile=en_US --charmap=UTF-8 --alias-file=/usr/share/locale/locale.alias en_US.UTF-8

ENV LANG en_US.UTF-8
ENV LANGUAGE=en_US

# RUN apt-get install -y ubuntu-gnome-desktop
# RUN apt-get install -y ubuntu-budgie-desktop budgie-indicator-applet
RUN apt-get install -y lubuntu-desktop lubuntu-restricted-addons lubuntu-restricted-extras

# RUN apt-get install -y pulseaudio cups iputils-ping libnss3 libxss1 xdg-utils libpango1.0-0 fonts-liberation
RUN apt install -y python3-pip

### NoMachine ###

# Goto https://www.nomachine.com/download/download&id=10 and update the latest 
ENV NOMACHINE_PACKAGE_NAME nomachine_8.2.3_4_amd64.deb
ENV NOMACHINE_BUILD 8.2
ENV NOMACHINE_MD5 f54fadba321d34e9745d25ec156bdacc

# Install nomachine, change password and username to whatever you want here
RUN curl -fSL "http://download.nomachine.com/download/${NOMACHINE_BUILD}/Linux/${NOMACHINE_PACKAGE_NAME}" -o nomachine.deb \
&& echo "${NOMACHINE_MD5} *nomachine.deb" | md5sum -c - && sudo dpkg -i nomachine.deb

# add to sudoers for all rights
RUN echo "%sudo ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

# user environment variable
ENV USER nomachine
ENV PASSWORD nomachine

# dbus setup
# workaround the fact that not all distros generate a machine-id when running inside container
# prevent dbus failures for lack of /var/run/dbus
ENV DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket
RUN mkdir -p /var/run/dbus
# RUN mkdir -p /var/lib/dbus && dbus-uuidgen > /var/lib/dbus/machine-id && mkdir -p /var/run/dbus

# edit the Nomachine node configuration;
# caution: both node.cfg and server.cfg files 
# must be edited for the changes to take effect;
# define the location and names of the config files
ARG NX_NODE_CFG=/usr/NX/etc/node.cfg
ARG NX_SRV_CFG=/usr/NX/etc/server.cfg
# (note we edit the config files *[i]n place* (hence sed -i)
# and replace *[c]omplete* lines using "c\" switch):
# - replace the default desktop command (DefaultDesktopCommand) used by NoMachine with the preferred (lightweight) desktop
RUN sed -i '/DefaultDesktopCommand/c\DefaultDesktopCommand "/usr/bin/startlxqt"' $NX_NODE_CFG
RUN sed -i '/DefaultDesktopCommand/c\DefaultDesktopCommand "/usr/bin/startlxqt"' $NX_SRV_CFG

# Install base utilities
RUN apt-get update && \
    apt-get install -y build-essential

# install flightmare required
RUN apt-get update && apt-get install -y --no-install-recommends \
   cmake \
   libzmqpp-dev \
   libopencv-dev 

# Cleanup
RUN apt-get autoclean \
   && apt-get autoremove \
   && rm -rf /var/lib/apt/lists/*

# listen to NX port (4000 by default)
EXPOSE 4000

# create a user account
RUN useradd -rm -d /home/${USER} -s /bin/bash -g root -G sudo -u 1000 ${USER}
RUN echo "${USER}:${PASSWORD}" | chpasswd

# make systemctl not go into graphical mode
# RUN ln -s /lib/systemd/system/systemd-logind.service /etc/systemd/system/multi-user.target.wants/systemd-logind.service
# RUN systemctl set-default multi-user.target

# use environment variables USER and PASSWORD (passed by docker run -e) 
# to create a priviledged user account, and set it up for use by SSH and NoMachine;
# note that ADD is executed by the host, not the container (unlike RUN)
ADD nxserver.sh /

ENTRYPOINT ["/nxserver.sh"]

RUN /etc/init.d/dbus start

WORKDIR /home/nomachine