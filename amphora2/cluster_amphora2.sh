#!/usr/bin/bash

memusage=10; #in gigabyte
ncores=4; #how many CPU cores can be addressed by the container
#$ -S /usr/bin/bash
#$ -N amphora2
#$ -e /vol/projects/sjanssen/dockerruns/ERR/
#$ -o /vol/projects/sjanssen/dockerruns/OUT/
#$ -pe multislot 4
#$ -l mem_free=10g
#$ -l virtual_free=10g
#$ -cwd

cd /vol/projects/sjanssen/docker_profiling_tools
docker build -f amphora2/Dockerfile_amphora2  -t amphora2 .
docker run --rm=true --memory=${memusage}g --memory-swap=-1 --cpuset-cpus=${ncores} \
-v "/vol/projects/sjanssen/CAMI/:/exchange/input" \
-v "/vol/projects/sjanssen/dockerruns/amphora2:/exchange/output:rw" \
-t amphora2
