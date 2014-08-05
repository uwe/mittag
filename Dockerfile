FROM phusion/baseimage
RUN apt-get update -y
RUN apt-get install -y build-essential perl libmysqlclient-dev
RUN curl -L http://cpanmin.us | perl - App::cpanminus

WORKDIR /home/app
ADD cpanfile /home/app/
RUN cpanm --notest --installdeps .

ADD . /home/app
RUN echo "{db_user=>'mittag',db_pass=>'mittag',db_host=>'mysql'}" >> config-local.pl

# start hypnotoad via runit
RUN mkdir /etc/service/mittag
ADD runit.sh /etc/service/mittag/run

# add cronjob (overwrites crontab)
RUN echo "0 6,8,10 * * 1,6,7 /home/app/bin/cronjob.sh" | crontab -

CMD ["/sbin/my_init"]
