provider "aws" {
    
  region = "ap-south-1"
}

data "aws_ami" "shopping-app" {
    
  owners = [ "self" ]

  most_recent = true  
    
  filter {
    name   = "name"
    values = ["zomato*"]
  }
    
  filter {
    name   = "tag:project"
    values = ["zomato"]
  }
    
  filter {
    name   = "tag:environment"
    values = ["dev"]
  } 
    
}





variable "project" {

  description = "project name"
  type        = string
  default     = "zomato"

}

variable "env" {
  description = " project environment"
  type        = string
  default     = "dev"

}

variable "domain_name" {
default = "devopstest2023.online"
}

variable "record_name" {
  description = "Name of record name"
  type        = string
  default     = "web-server-mumbai"

}



data "aws_route53_zone" "myzone" {
  name         = var.domain_name
  private_zone = false
}

# creating keypair

resource "aws_key_pair" "my_key" {
  key_name   = "${var.project}-${var.env}"
  public_key = file("zomato.pub")
  tags = {
    "Name"    = "zomato",
    "project" = "zomato",
    "env"     = "dev"
     }
}





resource "aws_security_group" "frontend" {
    
  name        = "zomato-frontend"
  description = "allows http & https traffic"
 
  ingress {

    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    "Name" = "zomato-frontend",
    "project" = "zomato",
    "env"     = "dev"
  }
}


resource "aws_instance"  "frontend" {
   
   ami = data.aws_ami.shopping-app.id
   instance_type = "t2.micro"
   key_name =  aws_key_pair.my_key.id
   vpc_security_group_ids = [ aws_security_group.frontend.id ]
   tags = {
       "Name" = "zomato-frontend",
       "project" = "zomato",
       "env" = "dev"
   } 
   lifecycle {
    create_before_destroy = true
  }
    
}



resource "aws_eip" "frontend" {
instance = aws_instance.frontend.id

  vpc      = true
   tags = {
    Name = "${var.project}-${var.env}-EIP"
  }
}

resource "aws_route53_record" "blog" {
  zone_id = data.aws_route53_zone.myzone.zone_id
  name    = var.record_name
  type    = "A"
  ttl     = 5
  records =  [aws_eip.frontend.public_ip] 
}

output "frontend_url" {
value = "http://${var.record_name}.${var.domain_name}"
}
