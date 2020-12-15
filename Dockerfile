FROM ubuntu:16.04

RUN apt update
RUN apt install -y python2.7 python-pip perl
RUN perl -MCPAN -e 'install XML::Simple'
ADD requirements.txt /requirements.txt
RUN cat requirements.txt | xargs -n 1 pip install

ENV CAMISIM=/usr/local/bin

ADD *.py $CAMISIM/
ADD scripts $CAMISIM/scripts
ADD tools $CAMISIM/tools
ADD defaults $CAMISIM/defaults
ADD ete2.patch /
RUN patch $(python -c "import ete2 as _; print(_.__path__[0])")/ncbi_taxonomy/ncbiquery.py ete2.patch

ADD docker_entrypoint.sh $CAMISIM/entrypoint.sh
ENTRYPOINT ["sh", "-c", "$CAMISIM/entrypoint.sh"]

RUN useradd -d /tmp camisim
USER camisim
