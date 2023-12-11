#!/bin/bash

ansible -m debug -a 'var=hostvars[inventory_hostname]' nas
