---
output:
  pdf_document: default
  html_document: default
---
# ProkaORF Shiny

## Step 1. Building the image

```bash
docker build -t prokaorf:v1 .
```

## Step 2. Running the image

```bash
docker run --rm --name prokaorf -p 8080:3838 \
    -v /srv/shinyapps/:/srv/shiny-server/ \
    -v /srv/shinylog/:/var/log/shiny-server/ \
    prokaorf:v1
```

OR

Run container in background and print container ID

```bash
docker run -d --rm -p 8080:3838 \
    -v /srv/shinyapps/:/srv/shiny-server/ \
    -v /srv/shinylog/:/var/log/shiny-server/ \
    prokaorf:v1
```

## Step 3: Using the ProkaORFShiny

Open the browser and access the URL: <http://localhost:8080>

## View R logs

```bash
docker logs prokaorf:v1
```

## Open terminal from container

```bash
sudo docker run -it --rm prokaorf:v1 bash
```

## Useful links (for developers)

- https://hosting.analythium.io/running-shiny-server-in-docker/
- https://github.com/analythium/covidapp-shiny/blob/913d17f152351bb58d0772b4f9d3db139ca05b05/04-docker-deps/Dockerfile
- https://blog.sellorm.com/2021/04/25/shiny-app-in-docker/
- https://gist.github.com/GeorgeSabu/43d3e8437f4b745c96d29b433b9356ee
- https://hub.docker.com/r/rocker/shiny
- https://gist.github.com/GeorgeSabu/43d3e8437f4b745c96d29b433b9356ee
- https://github.com/verbal-autopsy-software/openVA_App/blob/master/Dockerfile
