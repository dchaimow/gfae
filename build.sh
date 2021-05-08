#!/bin/bash

docker build --output type=tar,dest=gfae.tar --build-arg BUILDKIT_INLINE_CACHE=1 .

