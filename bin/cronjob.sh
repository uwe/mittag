#!/bin/bash

export LANG='de_DE.utf8'

cd /home/uwe/mittag
rm -f data/*
/opt/perl/bin/perl bin/download.pl
#tar -czf backup/`date +%Y-%m-%d-%H-%M`.tgz data
/opt/perl/bin/perl bin/extract.pl

