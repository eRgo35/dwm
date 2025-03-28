#!/bin/bash

rm -f config.h patches.h
make clean && make && sudo make install
