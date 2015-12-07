#!/usr/bin/bash

#$ -S /usr/bin/bash
#$ -N phylosift
#$ -e /vol/projects/sjanssen/dockerruns/ERR/
#$ -o /vol/projects/sjanssen/dockerruns/OUT/
#$ -pe multislot 4
#$ -cwd
#$ -l mem_free=40G 
#$ -l hostname=bioinf001

cd /vol/projects/sjanssen/docker_profiling_tools
docker build -f phylosift/Dockerfile_phylosift  -t phylosift .
docker run -v "/vol/projects/sjanssen/CAMI/:/exchange/input" -v "/vol/projects/sjanssen/dockerruns/phylosift:/exchange/output:rw" -t phylosift
