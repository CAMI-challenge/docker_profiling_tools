#!/usr/bin/bash

#$ -S /usr/bin/bash
#$ -N d_motu
#$ -e /vol/projects/sjanssen/dockerruns/ERR/
#$ -o /vol/projects/sjanssen/dockerruns/OUT/
#$ -pe multislot 4
#$ -cwd
#$ -l hostname=bioinf004

cd /home/sjanssen/docker_profiling_tools
docker build -f motu/Dockerfile  -t motu .
docker run -v "/vol/projects/sjanssen/CAMI/:/exchange/input" -v "/vol/projects/sjanssen/dockerruns/motu_1:/exchange/output:rw" -t motu
