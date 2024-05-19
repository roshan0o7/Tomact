module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "terraform-vpc"
  cidr = var.vpc_cidr

  azs                     = data.aws_availability_zones.azs.names
  private_subnets         = var.private_subnets
  enable_dns_hostnames    = true
  map_public_ip_on_launch = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
  public_subnet_tags = {
    Name = "terraform-subnet"
  }
}
#SG
module "sg" {
  source = "terraform-aws-modules/security-group/aws//modules/http-80"

  name        = "terraform-sg"
  description = "Security group for jenkins-server"
  vpc_id      = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "HTTP"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "ssh"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  tags = {
    name = "jenkins-sg"
  }
}
module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "webserver_server"

  instance_type               = var.instance_type
  key_name                    = "awsprofile-ci-key"
  monitoring                  = true
  vpc_security_group_ids      = [module.sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  ami                         = data.aws_ami.example.id
  associate_public_ip_address = true
  availability_zone           = data.aws_availability_zones.azs.names[0]
  user_data                   = file("Tomcat-install.sh")
  tags = {
    name        = "jenkins-server"
    Terraform   = "true"
    Environment = "dev"
  }
}
