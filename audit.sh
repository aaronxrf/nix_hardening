#!/bin/bash
git clone https://github.com/CISOfy/lynis
chown -R 0:0 ./lynis
cd lynis; ./lynis audit system