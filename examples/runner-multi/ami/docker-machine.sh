#!/usr/bin/env bash
set -ex

export DEBIAN_FRONTEND=noninteractive

apt -yq update
apt -yq install curl docker.io jq unzip

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.0.30.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
aws --version
ln -f "$(which aws)" /bin/aws
rm awscliv2.zip

usermod -aG docker ubuntu

systemctl start docker
systemctl enable docker

docker --version

docker pull docker:19.03.12
docker pull docker:19.03.12-dind
