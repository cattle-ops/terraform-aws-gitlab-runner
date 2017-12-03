#!/bin/bash

mkdir -p generated
ssh-keygen -t rsa -C "demo" -P '' -f generated/id_rsa
