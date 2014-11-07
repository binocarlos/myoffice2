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
RUN apt-get -y install curl make perl apache2 imagemagick build-essential cpanminus libapache2-mod-perl2 libapache2-mod-perl2-dev libapreq2-dev libapreq2 libapache2-request-perl apache2-prefork-dev
RUN apt-get clean

RUN cpanm --notest -v Apache2::Request
RUN cpanm --notest -v Data::Dumper
RUN cpanm --notest -v DBI
RUN cpanm --notest -v DBD::mysql
RUN cpanm --notest -v XML::DOM
RUN cpanm --notest -v MIME::Entity
RUN cpanm --notest -v JSON
RUN cpanm --notest -v Captcha::reCAPTCHA
RUN cpanm --notest -v File::Copy
RUN cpanm --notest -v HTML::Parse
RUN cpanm --notest -v HTML::FormatText
RUN cpanm --notest -v HTML::CalendarMonth
RUN cpanm --notest -v HTML::ElementRaw
RUN cpanm --notest -v LWP::Simple
RUN cpanm --notest -v Parse::RecDescent
RUN cpanm --notest -v String::Approx
RUN cpanm --notest -v String::Random
RUN cpanm --notest -v Date::EzDate
RUN cpanm --notest -v Time::Local
RUN cpanm --notest -v Number::Format
RUN cpanm --notest -v Text::Template
RUN cpanm --notest -v CGI::Session
RUN cpanm --notest -v Mail::Sendmail
RUN cpanm --notest -v Spreadsheet::WriteExcel
RUN cpanm --notest -v Spreadsheet::ParseExcel

# Turn on some crucial apache mods
RUN a2enmod rewrite headers apreq
RUN unlink /etc/apache2/mods-enabled/cgid.load
RUN unlink /etc/apache2/mods-enabled/cgid.conf

# Our start-up script
ADD . /home/webkitapps
ADD myoffice2.conf /etc/apache2/sites-enabled/myoffice2.conf

ADD start.sh /start.sh
RUN chmod a+x /start.sh

VOLUME ["/var/log"]

ENTRYPOINT ["/start.sh"]
EXPOSE 80