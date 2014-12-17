#!/bin/bash
while true
do
./generate-vm-pm-mapping.sh
./generate-pm-json.sh
sleep 5
done
