#!/usr/bin/bash

#$ -S /usr/bin/bash
#$ -N d_phylosift
#$ -e /vol/projects/sjanssen/dockerruns/ERR/
#$ -o /vol/projects/sjanssen/dockerruns/OUT/
#$ -pe multislot 4
#$ -cwd
#$ -l hostname=bioinf002
#$ -l mem_free=40G 

cd /home/sjanssen/docker_profiling_tools
docker build -f phylosift/Dockerfile_phylosift  -t phylosift .
docker run -v "/vol/projects/sjanssen/CAMI/:/exchange/input" -v "/vol/projects/sjanssen/dockerruns/phylosift_2:/exchange/output:rw" -t phylosift
