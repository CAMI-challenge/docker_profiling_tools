#!/usr/bin/bash

#$ -S /usr/bin/bash
#$ -N motu
#$ -e /vol/projects/sjanssen/dockerruns/ERR/
#$ -o /vol/projects/sjanssen/dockerruns/OUT/
#$ -pe multislot 4
#$ -cwd
#$ -l hostname=bioinf004

cd /vol/projects/sjanssen/docker_profiling_tools
docker build -f motu/Dockerfile  -t motu .
docker run -v "/vol/projects/sjanssen/CAMI/:/exchange/input" -v "/vol/projects/sjanssen/dockerruns/motu:/exchange/output:rw" -t motu
