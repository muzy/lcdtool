#!/bin/sh

IP="127.0.0.1"
PORT="48487"

echo "$@" | nc -q 1 $IP $PORT
