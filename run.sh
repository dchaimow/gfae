#!/bin/bash

xhost +localhost
docker run -it --rm -e DISPLAY=host.docker.internal:0 dchaimow/gfae  
