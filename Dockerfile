FROM phusion/baseimage
RUN apt-get update -y
RUN apt-get install -y build-essential perl libmysqlclient-dev
RUN curl -L http://cpanmin.us | perl - App::cpanminus

WORKDIR /home/app
ADD cpanfile /home/app/
RUN cpanm --notest --installdeps .
RUN cpanm --notest Starman

ADD . /home/app
RUN echo "{db_user=>'mittag',db_pass=>'mittag'}" >> config-local.pl

CMD hypnotoad script/mittag_web
