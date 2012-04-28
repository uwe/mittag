#!/bin/bash

cd /home/ec2-user/mittag
rm -f mail/*.txt
/opt/perl/bin/perl bin/mail-download.pl
#tar -czf backup/mail-`date +%Y-%m-%d-%H-%M`.tgz mail
/opt/perl/bin/perl bin/mail-extract.pl

