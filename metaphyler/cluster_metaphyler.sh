#!/bin/bash

#$ -S /bin/bash
#$ -N metaphyler
#$ -e /vol/projects/sjanssen/dockerruns/ERR/
#$ -o /vol/projects/sjanssen/dockerruns/OUT/
#$ -pe multislot 4
#$ -cwd
#$ -l hostname=bioinf005

cd /vol/projects/sjanssen/docker_profiling_tools
docker build -f metaphyler/Dockerfile  -t metaphyler .
docker run -v "/vol/projects/sjanssen/CAMI/:/exchange/input" -v "/vol/projects/sjanssen/dockerruns/metaphyler:/exchange/output:rw" -t metaphyler
