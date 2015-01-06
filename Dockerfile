FROM phusion/baseimage:latest

MAINTAINER Maurice Kaag <mkaag@me.com>

ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive
ENV DEBIAN_PRIORITY critical
ENV DEBCONF_NOWARNINGS yes
# Workaround initramfs-tools running on kernel 'upgrade': <http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=594189>
ENV INITRD No

# Workaround initscripts trying to mess with /dev/shm: <https://bugs.launchpad.net/launchpad/+bug/974584>
# Used by our `src/ischroot` binary to behave in our custom way, to always say we are in a chroot.
ENV FAKE_CHROOT 1
RUN mv /usr/bin/ischroot /usr/bin/ischroot.original
ADD build/ischroot /usr/bin/ischroot

# Configure no init scripts to run on package updates.
ADD build/policy-rc.d /usr/sbin/policy-rc.d

# Disable SSH
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

CMD ["/sbin/my_init"]

# Haproxy Installation
ENV CONFD_VERSION 0.7.1
ENV SSL_CERT false

RUN \
    sed -i 's/^# \(.*-backports\s\)/\1/g' /etc/apt/sources.list && \
    echo 'deb http://ppa.launchpad.net/vbernat/haproxy-1.5/ubuntu trusty main' >> /etc/apt/sources.list; \
    echo 'deb-src http://ppa.launchpad.net/vbernat/haproxy-1.5/ubuntu trusty main' >> /etc/apt/sources.list; \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 505D97A41C61B9CD; \
    apt-get update -qqy

RUN \
    apt-get install -qqy --no-install-recommends haproxy; \
    sed -i 's/^ENABLED=.*/ENABLED=1/' /etc/default/haproxy; \
    sed -i 's/^#$ModLoad imudp/$ModLoad imudp/' /etc/rsyslog.conf; \
    sed -i 's/^#$UDPServerRun 514/$UDPServerRun 514/' /etc/rsyslog.conf; \
    sed -i '/$UDPServerRun 514/a \$UDPServerAddress 127.0.0.1' /etc/rsyslog.conf; \
    touch /var/log/haproxy.log; \
    chown haproxy: /var/log/haproxy.log

ADD build/confd-watch /usr/local/bin/confd-watch
ADD build/haproxy.toml /etc/confd/conf.d/haproxy.toml
ADD build/haproxy.tmpl /etc/confd/templates/haproxy.tmpl

WORKDIR /usr/local/bin
RUN \
    curl -s -L https://github.com/kelseyhightower/confd/releases/download/v$CONFD_VERSION/confd-$CONFD_VERSION-linux-amd64 -o confd; \
    chmod +x confd; \
    chmod +x confd-watch

EXPOSE 80 443 1936
VOLUME ["/etc/ssl"]
# End Haproxy

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
