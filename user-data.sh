#!/bin/bash

sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker 