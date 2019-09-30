FROM ubuntu:18.04

ENV TOOLNAME metaphlan2

RUN apt-get update -y

ENV PACKAGES python-numpy python-biom-format python-biopython bowtie2 libxml-xpath-perl wget make xz-utils ca-certificates mercurial
RUN apt-get install -y --no-install-recommends ${PACKAGES}

ENV PREFIX /biobox

RUN mkdir -p ${PREFIX}/src/ ${PREFIX}/bin/ ${PREFIX}/lib/ ${PREFIX}/share/ 
ENV PATH=${PREFIX}/bin:${PATH}

ENV VALIDATOR /bbx/validator/
ENV BASE_URL https://s3-us-west-1.amazonaws.com/bioboxes-tools/validate-biobox-file
ENV VERSION  0.x.y
RUN mkdir -p ${VALIDATOR}

RUN wget \
      --quiet \
      --output-document -\
      ${BASE_URL}/${VERSION}/validate-biobox-file.tar.xz \
    | tar xJf - \
      --directory ${VALIDATOR} \
      --strip-components=1
ENV PATH ${PATH}:${VALIDATOR}

RUN wget -q -O ${PREFIX}/share/schema.yaml https://raw.githubusercontent.com/pbelmann/rfc/feature/new-profiling-inteface/container/profiling/schema.yaml

RUN hg clone https://bitbucket.org/biobakery/metaphlan2 -r 7ef7e6f ${PREFIX}/src/${TOOLNAME}

ENV GITHUB https://raw.githubusercontent.com/CAMI-challenge/docker_profiling_tools/master/
RUN wget -q -O ${PREFIX}/lib/Utils.pm ${GITHUB}/Utils.pm
RUN wget -q -O ${PREFIX}/lib/YAMLsj.pm ${GITHUB}/YAMLsj.pm
ADD task_${TOOLNAME}.pl ${PREFIX}/bin/task.pl

ENV YAML "/bbx/mnt/input/biobox.yaml"
ENTRYPOINT ["task.pl"]
