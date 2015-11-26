FROM ubuntu:14.04
MAINTAINER Stefan Janssen, stefan.janssen@helmholtz-hzi.de

ENV TOOLNAME phylosift

#list of all dependencies that can be satisfied via the package management system of Ubuntu
#ENV PACKAGES mercurial python-numpy python-biom-format bowtie2 libxml-xpath-perl wget
ENV PACKAGES wget
#directory where additional software shall be installed
ENV PREFIX /biobox/
ENV IO /exchange/

#update underlying linux system
RUN apt-get update -y

#install dependencies
RUN apt-get install -y --no-install-recommends ${PACKAGES}

#create prefix directory and src subdirectory
RUN mkdir -p ${PREFIX}/src
#download the latest version of PhyloSift
RUN wget -q -O ${PREFIX}/src/phylosift.tar.bz2 http://edhar.genomecenter.ucdavis.edu/~koadman/phylosift/phylosift_latest.tar.bz2
#extract downloaded archive
RUN tar xjvf ${PREFIX}/src/phylosift.tar.bz2 -C ${PREFIX}/src/
#determine directory name and rename this directory into ${TOOLNAME}
RUN cn=`find ${PREFIX}/src/ -name "phylosift_*" -type d` && mv $cn ${PREFIX}/src/${TOOLNAME}
#replace phylosifts own copy of the NCBI taxonomy with the latest one from NCBI's FTP server
RUN mkdir -p ${HOME}/share/phylosift/ncbi/
RUN wget -q -O ${HOME}/share/phylosift/ncbi/taxdump.tar.gz ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz
#note the download date of the NCBI taxonomy
RUN date +"%Y.%m.%d" > ${HOME}/share/phylosift/ncbi/taxdump.tar.gz.date

RUN sudo apt-get install curl

#metaphlan uses the GreenGenes taxonomy, while CAMI uses NCBI taxonomy. We thus need to find a mapping from GreenGenes to NCBI. I do this in a two step fashion: first, all used genomes (found in the "species2genomes.txt" file) are resolved to their according NCBI taxid with a Perl programm that must be run once. Second, every output of metaphlan must be converted via a second Perl script, which uses the mapping results from stage one.
#ENV MAPPERNAME IDmapper
#ENV MAPPERRESULT ${PREFIX}/share/${MAPPERNAME}/mappingresults.txt

#ADD ${TOOLNAME}/buildIDlists.pl ${TOOLNAME}/convert_${TOOLNAME}.pl Utils.pm ${PREFIX}/src/${MAPPERNAME}/
#ADD ${TOOLNAME}/workdir/Assembly_result.xml ${TOOLNAME}/workdir/bioproject_result.xml ${TOOLNAME}/workdir/manual.txt ${PREFIX}/share/${MAPPERNAME}/workdir/

#run the one time mapping from "species2genomes.txt" into NCBI taxids and store the result in $MAPPERRESULT
#since the NCBI taxonomy is not static, it might happen that some taxids are no longer used, i.e. the following program crashes. Try to manually update the XML files via the NCBI batch entrez system.
#RUN perl -I ${PREFIX}/src/${MAPPERNAME}/ ${PREFIX}/src/${MAPPERNAME}/buildIDlists.pl ${PREFIX}/src/${TOOLNAME}/utils/species2genomes.txt ${PREFIX}/share/${MAPPERNAME}/workdir > ${MAPPERRESULT} 
#should the previous command be successful, temporary files in workdir/Downloads can be deleted
#RUN rm -rf ${PREFIX}/share/${MAPPERNAME}/workdir/Downloads

#ADD ${SUBDIR}/task.pl ${PREFIX}/bin/
#RUN chmod a+x ${PREFIX}/bin/task.pl
#RUN mkdir -p ${IO}/input/
#RUN mkdir -p ${IO}/output/

#ENV CONT_FASTQ_FILE_LISTING ${IO}/input/inputfiles.txt
#ENV CONT_PROFILING_FILES ${IO}/output/

#ENV PATH=${PREFIX}/bin:${PATH}

#ENTRYPOINT ["task.pl"]
