# Use the official Python image based on Alpine as the base image
FROM python:3.13.1-alpine3.19 AS base

# Copy only the necessary files first to take advantage of caching
COPY pip_requirements.txt ansible_requirements.yml apk_packages.txt ./

# Upgrade pip to the latest version and install dependencies
RUN python -m pip install --upgrade pip && \
    apk update && \
    apk add --no-cache $(cat apk_packages.txt) \
        git curl unzip tar gcc make \
        libffi-dev libssl-dev libsqlite3-dev \
        musl-dev && \
    pip install --no-cache-dir -r pip_requirements.txt && \
    ansible-galaxy install -r ansible_requirements.yml && \
    rm -rf /var/cache/apk/* /tmp/*

# Clone Azure CLI repository
WORKDIR /app
RUN git clone https://github.com/Azure/azure-cli.git && \
    cd azure-cli && git checkout latest

# Install Azure CLI
WORKDIR /app/azure-cli
RUN python -m venv /app/venv && \
    source /app/venv/bin/activate && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir -r requirements_dev.txt && \
    pip install --no-cache-dir -e . && \
    pip install --no-cache-dir ansible ansible-lint yamllint

# Copy the ssh_config file to /root/.ssh/
COPY config/ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config

# Display ansible and linters version
RUN ansible --version && \
    ansible-lint --version && \
    yamllint --version

# Reduce final image size by removing unnecessary dev tools
FROM python:3.13.1-alpine3.19 AS final
WORKDIR /app

# Install only runtime dependencies
RUN apk add --no-cache \
    openssl libffi sqlite && \
    rm -rf /var/cache/apk/*

# Copy the built Azure CLI and Python environment
COPY --from=base /app/azure-cli /app/azure-cli
COPY --from=base /app/venv /app/venv

# Copy Ansible Galaxy roles
COPY --from=base /root/.ansible /root/.ansible

# Set the entrypoint
ENV PATH="/app/venv/bin:$PATH"
ENTRYPOINT ["az"]
