#!/bin/bash
set -e

curl -L https://tiny.cc/epicRaspberries | bash

touch /firstboot_was_here
