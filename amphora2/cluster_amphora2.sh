#!/usr/bin/bash

#$ -S /usr/bin/bash
#$ -N d_amphora2
#$ -e /vol/projects/sjanssen/dockerruns/ERR/
#$ -o /vol/projects/sjanssen/dockerruns/OUT/
#$ -pe multislot 4
#$ -cwd

cd /home/sjanssen/docker_profiling_tools
docker build -f amphora2/Dockerfile  -t amphora2 .
docker run -v "/vol/projects/sjanssen/CAMI/:/exchange/input" -v "/vol/projects/sjanssen/dockerruns/amphora2_1:/exchange/output:rw" -t amphora2
