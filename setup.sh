#!/bin/sh

# Install miniconda
CONDA_DIR=~/miniconda
wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
     /bin/bash ~/miniconda.sh -b -p ~/miniconda

# Put conda in path so we can use conda activate
touch ~/.bashrc
echo "PATH=$CONDA_DIR/bin:$PATH" >> ~/.bashrc
source ~/.bashrc

echo "export FLIGHTMARE_PATH=~/Documents/drone_offboard/flightmare_internal" >> ~/.bashrc
source ~/.bashrc

conda create -n flight python=3.8
conda activate flight

cd Documents/drone_offboard || exit
pip install -r requirements.txt