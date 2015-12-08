#!/usr/bin/bash

#$ -S /usr/bin/bash
#$ -N metaphlan2
#$ -e /vol/projects/sjanssen/dockerruns/ERR/
#$ -o /vol/projects/sjanssen/dockerruns/OUT/
#$ -pe multislot 4
#$ -cwd
#$ -l hostname=bioinf005

cd /vol/projects/sjanssen/docker_profiling_tools
docker build -f metaphlan2/Dockerfile  -t metaphlan2 .
docker run -v "/vol/projects/sjanssen/CAMI/:/exchange/input" -v "/vol/projects/sjanssen/dockerruns/metaphlan2:/exchange/output:rw" -t metaphlan2
