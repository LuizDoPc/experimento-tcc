#!/bin/bash
set -e

echo "Starting VM setup..."

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y curl wget git build-essential

echo "Installing Go..."
GO_VERSION="1.21.5"
wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
rm go${GO_VERSION}.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
export PATH=$PATH:/usr/local/go/bin

echo "Installing Java 17..."
sudo apt-get install -y openjdk-17-jdk
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' | sudo tee -a /etc/profile
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

echo "Installing Maven..."
MAVEN_VERSION="3.9.5"
wget -q https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz
sudo tar -xzf apache-maven-${MAVEN_VERSION}-bin.tar.gz -C /opt
rm apache-maven-${MAVEN_VERSION}-bin.tar.gz
sudo ln -sf /opt/apache-maven-${MAVEN_VERSION} /opt/maven
echo 'export M2_HOME=/opt/maven' | sudo tee -a /etc/profile
echo 'export PATH=$PATH:$M2_HOME/bin' | sudo tee -a /etc/profile
echo 'export M2_HOME=/opt/maven' >> ~/.bashrc
echo 'export PATH=$PATH:$M2_HOME/bin' >> ~/.bashrc
export M2_HOME=/opt/maven
export PATH=$PATH:$M2_HOME/bin

echo "Installing MySQL..."
sudo apt-get install -y mysql-server
sudo systemctl start mysql
sudo systemctl enable mysql

sleep 5
sudo mysql -e "CREATE DATABASE IF NOT EXISTS metrics;"
sudo mysql -e "CREATE USER IF NOT EXISTS 'admin'@'localhost' IDENTIFIED BY '123';"
sudo mysql -e "GRANT ALL PRIVILEGES ON metrics.* TO 'admin'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "Installing Protobuf compiler..."
PROTOC_VERSION="24.4"
wget -q https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip
sudo apt-get install -y unzip
sudo unzip -q protoc-${PROTOC_VERSION}-linux-x86_64.zip -d /usr/local
rm protoc-${PROTOC_VERSION}-linux-x86_64.zip
sudo chmod +x /usr/local/bin/protoc

echo "Installing Docker..."
sudo apt-get install -y ca-certificates gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker ubuntu

echo "Installing screen and tmux for long-running processes..."
sudo apt-get install -y screen tmux

echo "VM setup completed successfully!"

