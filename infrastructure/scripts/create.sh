#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

cd "$TERRAFORM_DIR"

if [ ! -f "terraform.tfvars" ]; then
    echo "Error: terraform.tfvars not found. Please create it from terraform.tfvars.example"
    echo "Copy terraform.tfvars.example to terraform.tfvars and fill in your values."
    exit 1
fi

echo "Initializing Terraform..."
terraform init

echo "Planning infrastructure..."
terraform plan

echo "Creating infrastructure..."
terraform apply -auto-approve

VM_IP=$(terraform output -raw vm_external_ip)
VM_NAME=$(terraform output -raw vm_name)
ZONE=$(terraform output -raw zone)

echo ""
echo "=========================================="
echo "Infrastructure created successfully!"
echo "=========================================="
echo "VM Name: $VM_NAME"
echo "External IP: $VM_IP"
echo "Zone: $ZONE"
echo ""
echo "Waiting for VM to be ready (this may take a few minutes)..."
echo "Checking VM status..."
for i in {1..30}; do
    if gcloud compute instances describe "$VM_NAME" --zone="$ZONE" --format="value(status)" | grep -q "RUNNING"; then
        echo "VM is running!"
        break
    fi
    echo "Waiting for VM to start... ($i/30)"
    sleep 10
done

echo ""
echo "Waiting additional time for startup script to complete..."
sleep 60

echo "Copying project files to VM..."
echo "This may take a few minutes depending on project size..."
echo "Note: Large directories like target/ and node_modules/ will be excluded..."

cd "$SCRIPT_DIR/../.."

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "Creating archive with exclusions..."
tar --exclude='target' \
    --exclude='node_modules' \
    --exclude='.git' \
    --exclude='*.csv' \
    --exclude='*.png' \
    --exclude='*.pdf' \
    --exclude='.terraform' \
    --exclude='terraform.tfstate*' \
    --exclude='*.jar' \
    --exclude='._*' \
    --exclude='.DS_Store' \
    -czf "$TEMP_DIR/experimento-tcc.tar.gz" . 2>/dev/null || {
    echo "Warning: tar failed, trying direct copy without exclusions..."
    gcloud compute scp --recurse --compress . "ubuntu@$VM_NAME:~/experimento-tcc" --zone="$ZONE" || {
        echo ""
        echo "Warning: Could not copy files automatically."
        echo "You can copy files manually using:"
        echo "  cd $(pwd)"
        echo "  gcloud compute scp --recurse . ubuntu@$VM_NAME:~/experimento-tcc --zone=$ZONE"
        echo ""
        exit 0
    }
    exit 0
}

echo "Uploading archive to VM..."
gcloud compute scp "$TEMP_DIR/experimento-tcc.tar.gz" "ubuntu@$VM_NAME:~/" --zone="$ZONE" || {
    echo ""
    echo "Warning: Could not upload archive."
    echo "You can copy files manually using gcloud scp."
    echo ""
    exit 0
}

echo "Extracting archive on VM..."
gcloud compute ssh "ubuntu@$VM_NAME" --zone="$ZONE" --command="mkdir -p ~/experimento-tcc && cd ~/experimento-tcc && tar -xzf ~/experimento-tcc.tar.gz && rm ~/experimento-tcc.tar.gz && find . -name '._*' -type f -delete 2>/dev/null || true && find . -name '.DS_Store' -type f -delete 2>/dev/null || true" || {
    echo "Warning: Could not extract archive on VM."
    echo "You may need to extract it manually after SSH:"
    echo "  ssh into VM and run: mkdir -p ~/experimento-tcc && cd ~/experimento-tcc && tar -xzf ~/experimento-tcc.tar.gz"
    echo "  Then clean macOS files: find . -name '._*' -type f -delete"
}

echo ""
echo "SSH into the VM:"
echo "  gcloud compute ssh ubuntu@$VM_NAME --zone=$ZONE"
echo ""
echo "Once inside the VM, run:"
echo "  cd ~/experimento-tcc/infrastructure/scripts"
echo "  bash deploy.sh"
echo "  cd ~/experimento-tcc/client"
echo "  ./lab-client"

