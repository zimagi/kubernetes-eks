#!/usr/bin/env bash
#-------------------------------------------------------------------------------
set -e

TOP_DIR="`pwd`"
APP_USER="${1:-vagrant}"
LOG_FILE="${2:-/dev/stderr}"
TIME_ZONE="${3:-America/New_York}"

if [ "$APP_USER" == 'root' ]
then
    APP_HOME="/root"
else
    APP_HOME="/home/${APP_USER}"
fi
#-------------------------------------------------------------------------------

export DEBIAN_FRONTEND=noninteractive

echo "Upgrading core OS packages" | tee -a "$LOG_FILE"
apt-get update -y >>"$LOG_FILE" 2>&1
apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade >>"$LOG_FILE" 2>&1

echo "Installing core dependencies" | tee -a "$LOG_FILE"
apt-get install -y \
        lsb-release \
        apt-utils \
        software-properties-common \
        ca-certificates \
        apt-transport-https \
        gnupg \
        curl \
        wget \
        unzip \
     >>"$LOG_FILE" 2>&1

echo "Syncronizing time" | tee -a "$LOG_FILE"
apt-get --yes install ntpdate >>"$LOG_FILE" 2>&1
ntpdate pool.ntp.org >>"$LOG_FILE" 2>&1

echo "Installing development tools" | tee -a "$LOG_FILE"
apt-get install -y \
        net-tools \
        git \
        g++ \
        gcc \
        make \
        python3-pip \
     >>"$LOG_FILE" 2>&1

echo "Installing Kubernetes CLI" | tee -a "$LOG_FILE"
wget -qO - https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - 2>/dev/null 1>&2
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list
apt-get update >>"$LOG_FILE" 2>&1
apt-get install -y kubectl >>"$LOG_FILE" 2>&1

echo "Installing Kubernetes Helm CLI" | tee -a "$LOG_FILE"
wget --output-document=/tmp/helm_install.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get 2>/dev/null
chmod 700 /tmp/helm_install.sh
/tmp/helm_install.sh -v v3.2.4 >>"$LOG_FILE" 2>&1

echo "Installing Terraform" | tee -a "$LOG_FILE"
wget --output-document=/tmp/terraform.zip https://releases.hashicorp.com/terraform/0.12.28/terraform_0.12.28_linux_amd64.zip 2>/dev/null
unzip -o /tmp/terraform.zip -d /usr/local/bin >>"$LOG_FILE" 2>&1
mkdir -p ~/.terraform.d/plugins

echo "Installing AWS CLI" | tee -a "$LOG_FILE"
rm -Rf /tmp/aws
wget --output-document=/tmp/aws.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip 2>/dev/null
unzip -o /tmp/aws.zip -d /tmp >>"$LOG_FILE" 2>&1
/tmp/aws/install --update >>"$LOG_FILE" 2>&1

echo "Installing AWS IAM Authenticator" | tee -a "$LOG_FILE"
wget --output-document=/usr/local/bin/aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.18.9/2020-11-02/bin/linux/amd64/aws-iam-authenticator 2>/dev/null
chmod 755 /usr/local/bin/aws-iam-authenticator
