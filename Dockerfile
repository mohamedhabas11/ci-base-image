# Use the official Python image based on Alpine as the base image
FROM python:3.9-alpine3.12

# Copy all required files
COPY . .

# Upgrade pip to the latest version
RUN python -m pip install --upgrade pip

# Install system dependencies and Ansible in a single layer
RUN apk update && \
    apk add --no-cache $(cat apk_packages.txt) && \
    pip install --no-cache-dir -r pip_requirements.txt && \
    ansible-galaxy install -r ansible_requirements.yml && \
    rm -rf /var/cache/apk/* /tmp/*

# Default command
CMD ["ansible", "--version"]
