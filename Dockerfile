# syntax=docker/dockerfile:1

###############
# Builder Stage
###############
FROM python:3.13.1-alpine3.19 AS builder

# Copy dependency lists
COPY apk_packages.txt pip_requirements.txt ansible_requirements.yml ./

# Install build-time packages and upgrade pip
RUN apk update && \
    apk add --no-cache $(cat apk_packages.txt) && \
    python -m pip install --upgrade pip

# Create a virtual environment and update PATH
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --upgrade pip

# Install Python dependencies into the venv (ensure ansible is included here, or install it separately)
RUN pip install --no-cache-dir -r pip_requirements.txt

# Now the ansible-galaxy command is available
RUN ansible-galaxy install -r ansible_requirements.yml

################
# Final Stage
################
FROM python:3.13.1-alpine3.19 AS final

# Copy the built virtual environment and Ansible artifacts from the builder stage
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /root/.ansible /root/.ansible

# Copy CLI packages list and install common CLI tools
COPY apk_cli_packages.txt ./
RUN apk update && \
    apk add --no-cache $(cat apk_cli_packages.txt)

# Copy SSH configuration and fix permissions
COPY config/ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config

# Set PATH to use the virtual environment’s binaries
ENV PATH="/opt/venv/bin:$PATH"

# (Optional) Display versions for verification
RUN ansible --version && ansible-lint --version && yamllint --version

CMD ["python"]
