FROM ubuntu:16.04

RUN apt update
RUN apt install -y python2.7 python-pip perl
RUN perl -MCPAN -e 'install XML::Simple'
ADD requirements.txt /requirements.txt
RUN perl -pi -e 'print "scipy==0.16.0\npandas==0.24.1\n" if ($.==2)' /requirements.txt
RUN cat requirements.txt | xargs -n 1 pip install

ENV CAMISIM=/usr/local/bin

ADD *.py $CAMISIM/
ADD scripts $CAMISIM/scripts
ADD tools $CAMISIM/tools
ADD defaults $CAMISIM/defaults
ADD ete2.patch /ete2.patch
RUN patch $(python -c "import ete2 as _; print(_.__path__[0])")/ncbi_taxonomy/ncbiquery.py /ete2.patch

RUN rm -rf /requirements.txt /ete2.patch /var/lib/{apt,dpkg,cache,log} ~/.cache ~/.cpan 

ENTRYPOINT ["sh", "-c", "$CAMISIM/scripts/container_entrypoint.sh"]
