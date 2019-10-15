FROM ubuntu:18.04

ENV TOOLNAME bracken

RUN apt-get update -y

ENV PACKAGES wget ca-certificates python3 make g++ xz-utils libxml-xpath-perl

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

RUN mkdir ${PREFIX}/src/kraken_tmp
RUN wget --quiet --output-document - https://github.com/DerrickWood/kraken2/archive/v2.0.8-beta.tar.gz | tar xz --strip-components=1 --directory ${PREFIX}/src/kraken_tmp
RUN mkdir ${PREFIX}/src/kraken
WORKDIR ${PREFIX}/src/kraken_tmp
RUN ./install_kraken2.sh ${PREFIX}/src/kraken
WORKDIR /
RUN rm -r ${PREFIX}/src/kraken_tmp

RUN mkdir ${PREFIX}/src/${TOOLNAME}
RUN wget --quiet --output-document - https://github.com/jenniferlu717/Bracken/archive/v2.5.tar.gz | tar xz --strip-components=1 --directory ${PREFIX}/src/${TOOLNAME}

ENV GITHUB https://raw.githubusercontent.com/CAMI-challenge/docker_profiling_tools/master/
RUN wget -q -O ${PREFIX}/lib/Utils.pm ${GITHUB}/Utils.pm
RUN wget -q -O ${PREFIX}/lib/YAMLsj.pm ${GITHUB}/YAMLsj.pm
ADD convert_${TOOLNAME}.py ${PREFIX}/bin/convert.py
ADD load_ncbi_taxinfo.py ${PREFIX}/bin/load_ncbi_taxinfo.py
ADD task_${TOOLNAME}.pl ${PREFIX}/bin/task.pl

ENV YAML "/bbx/mnt/input/biobox.yaml"
ENTRYPOINT ["task.pl"]
