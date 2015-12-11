#!/usr/bin/bash

memusage=40; #in gigabyte
ncores=4; #how many CPU cores can be addressed by the container
#$ -S /usr/bin/bash
#$ -N phylosift
#$ -e /vol/projects/sjanssen/dockerruns/ERR/
#$ -o /vol/projects/sjanssen/dockerruns/OUT/
#$ -pe multislot 4
#$ -l virtual_free=40g
#$ -l mem_free=40g
#$ -cwd

uname -a
cd /vol/projects/sjanssen/docker_profiling_tools
docker build -f phylosift/Dockerfile_phylosift  -t phylosift .
docker run --rm=true --memory=${memusage}g --memory-swap=-1 --cpuset-cpus=${ncores} \
-v "/vol/projects/sjanssen/CAMI/:/exchange/input" \
-v "/vol/projects/sjanssen/dockerruns/phylosift:/exchange/output:rw" \
-t phylosift
