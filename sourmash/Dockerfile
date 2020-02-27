FROM ubuntu:18.04

ENV TOOLNAME sourmash
ENV TOOLVERSION 3.2.2

RUN apt-get update -y

ENV PACKAGES wget ca-certificates python3 python3-pip python3-setuptools python3-wheel xz-utils libxml-xpath-perl

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

ENV PYTHON_PACKAGES taxonomy==0.4.1 pandas==1.0.1
RUN python3 -m pip install sourmash==${TOOLVERSION}
RUN python3 -m pip install ${PYTHON_PACKAGES}

ENV GITHUB https://raw.githubusercontent.com/CAMI-challenge/docker_profiling_tools/master/
RUN wget -q -O ${PREFIX}/lib/Utils.pm ${GITHUB}/Utils.pm
RUN wget -q -O ${PREFIX}/lib/YAMLsj.pm ${GITHUB}/YAMLsj.pm

ADD task_${TOOLNAME}.pl ${PREFIX}/bin/task.pl

ENV GITHUB_CONVERT https://raw.githubusercontent.com/dib-lab/2019-12-12-sourmash_viz/c72619d/
RUN wget -q -O ${PREFIX}/bin/convert.py ${GITHUB_CONVERT}/src/gather_to_opal.py
RUN chmod +x ${PREFIX}/bin/convert.py

ENV YAML "/bbx/mnt/input/biobox.yaml"
ENTRYPOINT ["task.pl"]
