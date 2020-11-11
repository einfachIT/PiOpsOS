#!/bin/bash
set -e
set -o pipefail

scriptname=`basename "$0"`
dirname=`dirname "$0"`

curl -L https://tiny.cc/epicRaspberries | bash

# rename script to disable initial provision service and enable update service
if [ $scriptname = "provision.sh" ]; then mv $dirname/provision.sh $dirname/update.sh
