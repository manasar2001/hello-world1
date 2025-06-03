provider "aws" {
  region = "us-east-1" # Change to your desired region
}

#  Create a Key Pair
resource "tls_private_key" "myprivatekey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = "mykey"
  public_key = tls_private_key.myprivatekey.public_key_openssh
}

resource "local_file" "private_key" {
  filename = "C:\\Users\\ManasaR\\Downloads\\mykey.pem"
  content  = tls_private_key.myprivatekey.private_key_pem
}

# Create EC2 Instance
resource "aws_instance" "myinstance" {
  ami             = "ami-0953476d60561c955" # Ubuntu AMI (change for your region)
  instance_type   = "t2.micro"
  key_name        = aws_key_pair.my_key_pair.key_name
  security_groups = [aws_security_group.allow_ssh.name]

  tags = {
    Name = "PythonServer1"
  }

  provisioner "file" {
    source      = "hello.py"
    destination = "/home/ec2-user/hello.py"
  }

 provisioner "remote-exec" {
  inline = [
    "sudo yum update -y",
    "sudo yum install python3 python3-pip -y",
    "pip3 install flask",
    "nohup python3 /home/ec2-user/hello.py &"
  ]
}

  connection {
    type        = "ssh"
    user        = "ec2-user"
    # private_key = file("C:\\Users\\ManasaR\\Downloads\\mykey.pem")
    private_key = tls_private_key.myprivatekey.private_key_pem
    host        = self.public_ip
  }
}

# Security Group for SSH & Flask
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH & Flask inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open Flask app to public
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
output "instance_public_ip" {
  description = "Public IP of the Flask Server"
  value       = aws_instance.myinstance.public_ip
}



#connect to your ec2 instance in command prompt by using command ssh -i "C:\Users\ManasaR\Downloads\mykey.pem" ec2-user@3.87.210.143 [ make sure to put proper path and current IP address]
#sudo yum install python3-pip -y : after connecting to ec2 give this command, this installs python
# pip3 --version : to check whether its installed
# pip3 install flask : this command installs flask inside your instance
# python3 /home/ec2-user/hello.py : give this command to run ur python code 

# ####################################################################################
# connect through browser :-> http://http://3.87.210.143:5000  :->here give your public ip of instnace it will be shown here after running apply and u can get from console, :5000 is the port where u have to run your code which u have specified in code aswell