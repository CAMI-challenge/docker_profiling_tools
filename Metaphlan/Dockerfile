FROM ubuntu:14.04
MAINTAINER Stefan Janssen, stefan.janssen@helmholtz-hzi.de

#list of all dependencies that can be satisfied via the package management system of Ubuntu
ENV PACKAGES mercurial python-numpy python-biom-format bowtie2
#directory where additional software shall be installed
ENV PREFIX /biobox/


#update underlying linux system
RUN apt-get update -y

#install dependencies
RUN apt-get install -y --no-install-recommends ${PACKAGES}

#create prefix directory and src subdirectory
RUN mkdir -p ${PREFIX}/src
#adding fingerprint for bitbucket.org for seamless hg cloning from that site
RUN echo "[hostfingerprints]" >> ~/.hgrc && echo "bitbucket.org = 46:de:34:e7:9b:18:cd:7f:ae:fd:8b:e3:bc:f4:1a:5e:38:d7:ac:24" >> ~/.hgrc
#download the latest version of MetaPhlAn2
RUN hg clone https://bitbucket.org/biobakery/metaphlan2 ${PREFIX}/src/metaphlan2



