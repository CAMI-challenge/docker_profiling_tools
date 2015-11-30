#!/usr/bin/bash

#$ -S /usr/bin/bash
#$ -N d_phylosift
#$ -e /home/sjanssen/dockerruns/ERR/
#$ -o /home/sjanssen/dockerruns/OUT/
#$ -pe multislot 4
#$ -cwd

cd /home/sjanssen/docker_profiling_tools
docker build -f phylosift/Dockerfile_phylosift  -t phylosift .
docker run -v "/vol/projects/sjanssen/CAMI/:/exchange/input" -v "/home/sjanssen/dockerruns/phylosift_1:/exchange/output:rw" -t phylosift
