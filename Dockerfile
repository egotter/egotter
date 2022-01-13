# docker build -t egotter-ubuntu:latest .
# docker run -it egotter-ubuntu
# docker exec -it [CONTAINER ID] /bin/bash --login

FROM ubuntu

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND noninteractive
ENV USERDIR /home/root
ENV APPDIR /home/root/egotter
ENV RUBY_VERSION 2.7.4

RUN mkdir $USERDIR
WORKDIR $USERDIR

RUN apt update -y
RUN apt upgrade -y
RUN apt install -y build-essential
RUN apt install -y libssl-dev libreadline-dev zlib1g-dev
RUN apt install -y libidn11-dev
RUN apt install -y redis nginx nodejs
RUN apt install -y mysql-client libmysqlclient-dev
RUN apt install -y mecab libmecab-dev mecab-ipadic-utf8
RUN apt install -y unzip systemd sudo git curl wget vim


RUN wget http://cache.ruby-lang.org/pub/ruby/2.7/ruby-${RUBY_VERSION}.tar.gz
RUN tar xvfz ruby-${RUBY_VERSION}.tar.gz
WORKDIR ${USERDIR}/ruby-${RUBY_VERSION}
RUN ./configure && make && make install
WORKDIR $USERDIR

# RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
COPY ./pubkey.gpg /tmp
RUN cat /tmp/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" >>/etc/apt/sources.list.d/yarn.list
RUN apt-get update
RUN apt-get install -y yarn
RUN apt install -y python2
RUN rm /tmp/pubkey.gpg

# RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && ./aws/install

RUN echo "export PS1='\[\e[36;1m\][\w]\$\[\e[m\] '" >>~/.bashrc
RUN echo "alias be='bundle exec'" >>~/.bashrc

#RUN apt install -y locales
#RUN locale-gen ja_JP.UTF-8
#RUN update-locale LANG=ja_JP.UTF-8
#RUN echo "export LANG=ja_JP.UTF-8" >>~/.bashrc

#RUN apt install -y python3-pip
