resource "aws_instance" "ec2" { 
  ami           = data.aws_ami.amazon-linux-2.id
  instance_type = local.instance_type
  vpc_security_group_ids = [aws_security_group.sg.id]
  user_data     = <<-EOF
        #!/bin/bash

        # Update the system
        yum update -y

        ###########JENKINS###############
        # Add Jenkins repository
        sudo wget -O /etc/yum.repos.d/jenkins.repo \
        https://pkg.jenkins.io/redhat-stable/jenkins.repo
        sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
        # Install Java, Jenkins, Git, and jq
        yum upgrade -y
        amazon-linux-extras install java-openjdk11 -y
        yum install jenkins git jq -y
        # Start Jenkins service
        systemctl enable jenkins
        systemctl start jenkins

        ###########DOCKER################
        # Install Docker
        yum install -y docker
        # Start Docker service
        systemctl enable docker
        systemctl start docker
        # Add Jenkins user to the docker group
        usermod -aG docker jenkins

        ############KUBECTLandHELM##########
        # Install kubectl
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        # Install Helm
        curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
        chmod 700 get_helm.sh
        ./get_helm.sh

        #############INSTALL MINIKUBE###########
        # Install Minikube
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
        install minikube-linux-amd64 /usr/local/bin/minikube
        # Set shell for jenkins user to bash
        usermod -s /bin/bash jenkins
        # Set password for jenkins user (not recommended for production)
        echo -e "123\n123" | sudo passwd jenkins
        # Start Minikube (assuming it's configured correctly)
        su - jenkins -c "minikube start --disk-size 10000mb"

EOF
  iam_instance_profile = aws_iam_instance_profile.profile.name
  tags = {
    Name = "Jenkins"
  }
  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }
}

