FROM ubuntu:12.04

MAINTAINER Kai Davenport, kaiyadavenport@gmail.com

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update
RUN apt-get -y install curl apache2 imagemagick libapache2-mod-perl2

# Turn on some crucial apache mods
RUN a2enmod rewrite headers

# Our start-up script

ADD httpd.conf /etc/apache2/apache2.conf
ADD start.sh /start.sh
RUN chmod a+x /start.sh

VOLUME ["/var/log"]

ENTRYPOINT ["/start.sh"]
EXPOSE 80