#!/usr/bin/bash

memusage=10; #in gigabyte
#$ -S /usr/bin/bash
#$ -N motu
#$ -e /vol/projects/sjanssen/dockerruns/ERR/
#$ -o /vol/projects/sjanssen/dockerruns/OUT/
#$ -pe multislot 4
#$ -l mem_free=10g
#$ -cwd

cd /vol/projects/sjanssen/docker_profiling_tools
docker build -f motu/Dockerfile_motu  -t motu .
docker run --memory=${memusage}g --memory-swap=-1 \
-v "/vol/projects/sjanssen/CAMI/:/exchange/input" \
-v "/vol/projects/sjanssen/dockerruns/motu:/exchange/output:rw" \
-t motu
