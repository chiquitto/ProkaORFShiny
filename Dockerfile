# FROM rocker/shiny:4.2.0
# FROM r-base:4.2.0
FROM rocker/tidyverse:4.2.0

LABEL maintainer="Alisson G. Chiquitto <chiquitto@gmail.com>"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    patch \
    libcurl4-gnutls-dev \
    libssl-dev \
    python3-pip \
    nano \
    libpython3-dev \
    libbz2-dev \
    liblzma-dev \
    && pip install pandas

COPY Rprofile.site /etc/R
ENV _R_SHLIB_STRIP_=true

# RUN echo "local(options(shiny.port = 3838, shiny.host = '0.0.0.0'))" > /usr/lib/R/etc/Rprofile.site
# RUN echo "local(options(shiny.port = 3838, shiny.host = '0.0.0.0'))" > /etc/Rprofile.site

RUN addgroup --system pouser && adduser --system --ingroup pouser pouser
WORKDIR /home/pouser

COPY ProkaORFInstall.R /home/pouser/ProkaORFInstall.R
RUN R -f /home/pouser/ProkaORFInstall.R

COPY app /home/pouser/app

RUN chown pouser:pouser -R /home/pouser
USER pouser

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/home/pouser/app', port = 3838, host = '0.0.0.0')"]
