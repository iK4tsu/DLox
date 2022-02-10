#!/bin/sh
dmd -unittest -preview=dip1000 -version=dlox_unittest -g -betterC \
    -I=source \
    -i -run source/app.d
