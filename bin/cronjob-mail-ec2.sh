#!/bin/bash

source /home/ec2-user/perl5/perlbrew/etc/bashrc

cd /home/ec2-user/mittag
perl bin/mail-download.pl
tar -czf backup/mail-`date +%Y-%m-%d-%H-%M`.tgz mail
perl bin/mail-extract.pl

