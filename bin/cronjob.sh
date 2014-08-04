#!/bin/bash

cd /home/app
rm -f data/*
perl bin/download.pl
perl bin/extract.pl
