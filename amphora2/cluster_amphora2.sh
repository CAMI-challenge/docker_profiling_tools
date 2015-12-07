#!/usr/bin/bash

#$ -S /usr/bin/bash
#$ -N amphora2
#$ -e /vol/projects/sjanssen/dockerruns/ERR/
#$ -o /vol/projects/sjanssen/dockerruns/OUT/
#$ -pe multislot 4
#$ -cwd
#$ -l hostname=bioinf002

cd /vol/projects/sjanssen/docker_profiling_tools
docker build -f amphora2/Dockerfile  -t amphora2 .
docker run -v "/vol/projects/sjanssen/CAMI/:/exchange/input" -v "/vol/projects/sjanssen/dockerruns/amphora2:/exchange/output:rw" -t amphora2
