#!/bin/sh
N=0
while docker rm -f amba$N; do
    N=$(($N+1))
done
