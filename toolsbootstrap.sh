# This setup is intended to be run in an insecure development environment only. Consider your development environment security practices before use.

# Add user to sudoers if not already added
if ! sudo grep -q '^sysadmin ALL=(ALL) NOPASSWD:ALL' /etc/sudoers.d/sysadmin 2>/dev/null; then
	echo 'sysadmin ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/sysadmin
else
    echo "User already added to sudoers."
fi

# Install Terraform if not installed
if ! command -v terraform > /dev/null; then
    echo "Installing Terraform..."

    # Install Terraform installer dependencies
    sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

    # Add HashiCorp GPG key
    wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

    # Verify key
    gpg --no-default-keyring \
    --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    --fingerprint

    # Add HashiCorp repository
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list

    # Install Terraform
    sudo apt-get update && sudo apt-get install -y terraform
else
    echo "Terraform already installed."
fi

# Install Docker if not installed - convenience script method.
# Docker will be used for running Hashicorp Vault and possibly some other supporting core services
if ! command -v docker > /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker sysadmin
    sudo systemctl enable docker
    sudo systemctl start docker
else
    echo "Docker already installed."
fi

# Install Azure CLI if not installed
if ! command -v az > /dev/null; then
    echo "Installing Azure CLI..."
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
else
    echo "Azure CLI already installed."
fi
