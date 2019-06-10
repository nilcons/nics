FROM debian:buster-20190506
RUN apt-get update && \
    apt-get -y install texlive-latex-base texlive-latex-extra texlive-luatex texlive-xetex \
                       make zip time imagemagick jigl python3-pygments gnuplot-nox poppler-utils
VOLUME /slides
VOLUME /nics
WORKDIR /slides
