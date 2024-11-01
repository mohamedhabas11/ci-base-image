# Use the official Python image based on Alpine as the base image
FROM python:3.9-alpine3.12 AS base

# Copy only the necessary files first to take advantage of caching
COPY pip_requirements.txt .
COPY ansible_requirements.yml .

# Upgrade pip to the latest version and install dependencies
RUN python -m pip install --upgrade pip && \
    apk update && \
    apk add --no-cache $(cat apk_packages.txt) && \
    pip install --no-cache-dir -r pip_requirements.txt && \
    ansible-galaxy install -r ansible_requirements.yml && \
    rm -rf /var/cache/apk/* /tmp/*

# Copy the rest of the application code
COPY . .

# Display ansible version
RUN ansible --version
