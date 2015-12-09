#!/usr/bin/bash

memusage=40; #in gigabyte
#$ -S /usr/bin/bash
#$ -N phylosift
#$ -e /vol/projects/sjanssen/dockerruns/ERR/
#$ -o /vol/projects/sjanssen/dockerruns/OUT/
#$ -pe multislot 4
#$ -l mem_free=40g
#$ -cwd

cd /vol/projects/sjanssen/docker_profiling_tools
docker build -f phylosift/Dockerfile_phylosift  -t phylosift .
docker run --memory=${memusage}g --memory-swap=-1 \
-v "/vol/projects/sjanssen/CAMI/:/exchange/input" \
-v "/vol/projects/sjanssen/dockerruns/phylosift:/exchange/output:rw" \
-t phylosift
