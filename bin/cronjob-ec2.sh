#!/bin/bash

source /home/ec2-user/perl5/perlbrew/etc/bashrc

cd /home/ec2-user/mittag
perl bin/download.pl
tar -czf `date +%Y-%m-%d`.tgz data
perl bin/extract.pl

