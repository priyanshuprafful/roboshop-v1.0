terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
  }
}
resource "aws_instance" "server" {
  ami = data.aws_ami.ami_example.id
  instance_type = "t3.small"
  vpc_security_group_ids = [aws_security_group.sg.id]

  tags = {
    Name = var.name
  }


}

resource "null_resource" "ansible_tasks" { # no need to keep inside the server , as if this fails then we have to re create the instances as well
  depends_on = [aws_instance.server , aws_route53_record.server_dns_record] # only after this it should run 
  provisioner "remote-exec" {

    connection {
      type = "ssh"
      user = "centos"
      password = "DevOps321"
      host = aws_instance.server.public_ip
    }

    inline = [

      "sudo labauto ansible",
      "ansible-pull -i localhost, -U https://github.com/priyanshuprafful/roboshop-ansible-2.0 main.yml -e env=dev -e role_name=${var.name}"

    ]
  }
}

resource "aws_route53_record" "server_dns_record" {
  zone_id = "Z07509333FKRUTQBWWVPR"
  name    = "${var.name}-dev"
  type    = "A"
  ttl     = 30
  records = [aws_instance.server.private_ip]
}
data "aws_ami" "ami_example"{
  owners = ["973714476881"]
  most_recent = true
  name_regex = "Centos-8-DevOps-Practice"
}

resource "aws_security_group" "sg" {
  name = var.name
  description = "Allow TLS inbound traffic"

  ingress { # Now this has become allow-all kind of configuration , we are allowing all the traffic to enter
   # description = "SSH"
    from_port = 0
    to_port = 0
    protocol = "-1" #"tcp" -1 means all the traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = var.name
  }
}

variable "name" {}