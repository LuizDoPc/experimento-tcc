# Google Cloud Infrastructure Setup

This directory contains all the infrastructure and deployment scripts needed to run the lab experiment on Google Cloud Platform.

## Prerequisites

Before you begin, you need to:

1. **Create a Google Cloud Account**
   - Go to https://cloud.google.com/
   - Sign up for a free trial (includes $300 credit)
   - Create a new project

2. **Install Google Cloud SDK (gcloud)**
   
   **On macOS:**
   ```bash
   brew install google-cloud-sdk
   ```
   
   **On Linux:**
   ```bash
   curl https://sdk.cloud.google.com | bash
   exec -l $SHELL
   ```
   
   **On Windows:**
   - Download from https://cloud.google.com/sdk/docs/install
   - Run the installer

3. **Install Terraform**
   
   **On macOS:**
   ```bash
   brew install terraform
   ```
   
   **On Linux:**
   ```bash
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```
   
   **On Windows:**
   - Download from https://www.terraform.io/downloads
   - Add to PATH

4. **Authenticate with Google Cloud**
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```

5. **Set up your project**
   ```bash
   gcloud config set project YOUR_PROJECT_ID
   gcloud config set compute/region us-central1
   gcloud config set compute/zone us-central1-a
   ```

6. **Enable required APIs**
   ```bash
   gcloud services enable compute.googleapis.com
   gcloud services enable iam.googleapis.com
   ```

7. **Generate SSH key (if you don't have one)**
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
   ```

## Setup Instructions

1. **Configure Terraform variables**
   ```bash
   cd infrastructure/terraform
   cp terraform.tfvars.example terraform.tfvars
   ```
   
   Edit `terraform.tfvars` and set your `project_id`:
   ```hcl
   project_id = "your-gcp-project-id"
   ```

2. **Create the infrastructure**
   ```bash
   cd infrastructure/scripts
   bash create.sh
   ```
   
   This will:
   - Create a VM instance in Google Cloud
   - Set up all required software (Go, Java, Maven, MySQL, etc.)
   - Copy your project files to the VM
   - Provide you with SSH instructions

3. **SSH into the VM and deploy**
   ```bash
   gcloud compute ssh ubuntu@lab-experiment-vm --zone=us-central1-a
   ```
   
   Once inside the VM:
   ```bash
   cd ~/experimento-tcc/infrastructure/scripts
   bash deploy.sh
   ```

4. **Run the lab client**
   ```bash
   cd ~/experimento-tcc/client
   ./lab-client
   ```

## Destroying Infrastructure

**IMPORTANT**: Always destroy the infrastructure when you're done to avoid unnecessary charges!

```bash
cd infrastructure/scripts
bash destroy.sh
```

This will:
- Delete the VM instance
- Release the static IP address
- Remove all firewall rules
- Clean up all resources

## Manual Steps (Alternative)

If you prefer to run Terraform manually:

1. **Initialize Terraform**
   ```bash
   cd infrastructure/terraform
   terraform init
   ```

2. **Review the plan**
   ```bash
   terraform plan
   ```

3. **Apply the configuration**
   ```bash
   terraform apply
   ```

4. **Destroy when done**
   ```bash
   terraform destroy
   ```

## Cost Estimation

The default VM configuration (`e2-standard-4`) costs approximately:
- **$0.134/hour** (~$3.22/day)
- **~$97/month** if running 24/7

**Important**: Always destroy the VM when not in use to avoid charges!

## Troubleshooting

### OAuth2 Authentication Errors ("invalid_grant")

If you see errors like:
```
Error: oauth2: "invalid_grant" "Bad Request"
```

This means your Google Cloud credentials have expired. Fix it by:

```bash
gcloud auth login
gcloud auth application-default login
```

### SSH Connection Issues
```bash
gcloud compute config-ssh
gcloud compute ssh ubuntu@lab-experiment-vm --zone=us-central1-a
```

### VM Not Starting
- Check the VM status: `gcloud compute instances describe lab-experiment-vm --zone=us-central1-a`
- View logs: `gcloud compute instances get-serial-port-output lab-experiment-vm --zone=us-central1-a`

### Build Failures
- Ensure all dependencies are installed: `bash infrastructure/scripts/vm-setup.sh`
- Check Go version: `go version` (should be 1.21+)
- Check Java version: `java -version` (should be 17+)
- Check Maven: `mvn --version`

### MySQL Connection Issues
```bash
sudo systemctl status mysql
sudo systemctl start mysql
mysql -u admin -p123 -e "USE metrics;"
```

## Running Long-Running Processes

When you need to run processes that take a long time (like the lab client), see [SSH_PROCESSOS_LONGOS.md](SSH_PROCESSOS_LONGOS.md) for detailed instructions on:
- Using `screen` or `tmux` to keep processes running after SSH disconnection
- Using `nohup` for background processes
- Setting up systemd services
- Viewing and monitoring logs

Quick example with screen:
```bash
# SSH into VM
gcloud compute ssh ubuntu@lab-experiment-vm --zone=us-central1-a

# Start screen session
screen -S lab-client

# Run your process
cd ~/experimento-tcc/client && ./lab-client

# Detach: Ctrl+A then D
# Reconnect later: screen -r lab-client
```

## Files Structure

```
infrastructure/
├── terraform/
│   ├── main.tf              # Main Terraform configuration
│   ├── variables.tf         # Variable definitions
│   ├── outputs.tf          # Output values
│   └── terraform.tfvars.example  # Example configuration
├── scripts/
│   ├── vm-setup.sh         # VM initialization script
│   ├── build-all.sh        # Build all applications
│   ├── deploy.sh           # Deployment script
│   ├── create.sh           # Create infrastructure
│   └── destroy.sh           # Destroy infrastructure
├── README.md               # This file
└── SSH_PROCESSOS_LONGOS.md # Guide for long-running processes
```

