#!/usr/bin/bash

#$ -S /usr/bin/bash
#$ -N d_metaphlan2
#$ -e /home/sjanssen/dockerruns/ERR/
#$ -o /home/sjanssen/dockerruns/OUT/
#$ -pe multislot 4
#$ -cwd

cd /home/sjanssen/docker_profiling_tools
docker build -f metaphlan2/Dockerfile  -t metaphlan2 .
docker run -v "/vol/projects/sjanssen/CAMI/:/exchange/input" -v "/home/sjanssen/dockerruns/metaphlan2_1:/exchange/output:rw" -t metaphlan2
