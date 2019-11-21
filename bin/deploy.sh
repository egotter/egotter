#!/usr/bin/env bash

for i in $(seq 3 8); do
  ssh egotter_web${i} "$1"
  sleep 30
done
