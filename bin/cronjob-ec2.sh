#!/bin/bash

source /home/ec2-user/perl5/perlbrew/etc/bashrc

cd /home/ec2-user/mittag
rm -f data/*
perl bin/download.pl
tar -czf backup/`date +%Y-%m-%d-%H-%M`.tgz data
perl bin/extract.pl

