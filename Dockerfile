# Use the official Python image based on Alpine as the base image
FROM python:3.13.1-alpine3.19 AS base

# Copy only the necessary files first to take advantage of caching
COPY pip_requirements.txt ansible_requirements.yml apk_packages.txt ./

# Upgrade pip to the latest version and install dependencies
RUN python -m pip install --upgrade pip && \
    apk update && \
    apk add --no-cache $(cat apk_packages.txt) && \
    pip install --no-cache-dir -r pip_requirements.txt && \
    ansible-galaxy install -r ansible_requirements.yml && \
    rm -rf /var/cache/apk/* /tmp/*

# Copy the ssh_config file to /root/.ssh/
COPY config/ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config

# Display ansible and linters version
RUN ansible --version && \
    ansible-lint --version && \
    yamllint --version
