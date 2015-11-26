FROM ubuntu:14.04
MAINTAINER Stefan Janssen, stefan.janssen@helmholtz-hzi.de

ENV TOOLNAME metaphlan2 

#list of all dependencies that can be satisfied via the package management system of Ubuntu
ENV PACKAGES mercurial python-numpy python-biom-format bowtie2 libxml-xpath-perl wget
#directory where additional software shall be installed
ENV PREFIX /biobox/
ENV IO /exchange/

#update underlying linux system
RUN apt-get update -y

#install dependencies
RUN apt-get install -y --no-install-recommends ${PACKAGES}

#create prefix directory and src subdirectory
RUN mkdir -p ${PREFIX}/src
#adding fingerprint for bitbucket.org for seamless hg cloning from that site
RUN echo "[hostfingerprints]" >> ~/.hgrc && echo "bitbucket.org = 46:de:34:e7:9b:18:cd:7f:ae:fd:8b:e3:bc:f4:1a:5e:38:d7:ac:24" >> ~/.hgrc
#download the latest version of MetaPhlAn2
RUN hg clone https://bitbucket.org/biobakery/metaphlan2 ${PREFIX}/src/${TOOLNAME}

#metaphlan uses the GreenGenes taxonomy, while CAMI uses NCBI taxonomy. We thus need to find a mapping from GreenGenes to NCBI. I do this in a two step fashion: first, all used genomes (found in the "species2genomes.txt" file) are resolved to their according NCBI taxid with a Perl programm that must be run once. Second, every output of metaphlan must be converted via a second Perl script, which uses the mapping results from stage one.
ENV MAPPERNAME IDmapper
ENV MAPPERRESULT ${PREFIX}/share/${MAPPERNAME}/mappingresults.txt

ADD ${TOOLNAME}/buildIDlists.pl ${TOOLNAME}/convert_${TOOLNAME}.pl Utils.pm ${PREFIX}/src/${MAPPERNAME}/
ADD ${TOOLNAME}/workdir/Assembly_result.xml ${TOOLNAME}/workdir/bioproject_result.xml ${TOOLNAME}/workdir/manual.txt ${PREFIX}/share/${MAPPERNAME}/workdir/

#run the one time mapping from "species2genomes.txt" into NCBI taxids and store the result in $MAPPERRESULT
#since the NCBI taxonomy is not static, it might happen that some taxids are no longer used, i.e. the following program crashes. Try to manually update the XML files via the NCBI batch entrez system.
RUN perl -I ${PREFIX}/src/${MAPPERNAME}/ ${PREFIX}/src/${MAPPERNAME}/buildIDlists.pl ${PREFIX}/src/${TOOLNAME}/utils/species2genomes.txt ${PREFIX}/share/${MAPPERNAME}/workdir > ${MAPPERRESULT} 
#should the previous command be successful, temporary files in workdir/Downloads can be deleted
RUN rm -rf ${PREFIX}/share/${MAPPERNAME}/workdir/Downloads

ADD ${TOOLNAME}/task.pl ${PREFIX}/bin/
RUN chmod a+x ${PREFIX}/bin/task.pl
RUN mkdir -p ${IO}/input/
RUN mkdir -p ${IO}/output/

ENV CONT_FASTQ_FILE_LISTING ${IO}/input/inputfiles.txt
ENV CONT_PROFILING_FILES ${IO}/output/

ENV PATH=${PREFIX}/bin:${PATH}

ENTRYPOINT ["task.pl"]
