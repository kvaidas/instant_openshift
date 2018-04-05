/*
    Variables
*/

variable "aws_access_key" {
    type = "string"
}

variable "aws_secret_key" {
    type = "string"
}

variable "aws_region" {
    type = "string"
}

variable "aws_instance_size" {
    type = "string"
    default = "t2.micro"
}

variable "aws_public_key" {
    type = "string"
}

variable "openshift_username" {
    type = "string"
}

variable "openshift_password" {
    type = "string"
}



/*
    Provider-specific settings
*/

provider "aws" {
    region = "${var.aws_region}"
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
}



/*
    Select the required AMI
*/

data "aws_ami" "default_ami" {
    filter {
        name = "virtualization-type"
        values = [ "hvm" ]
    }

    filter {
        name = "owner-id"
        values = [ "679593333241" ]
    }

    filter {
        name = "name"
        values = [ "CentOS Linux 7 x86_64*" ]
    }

    most_recent = "true"
}

# Store it as a variable
output "ami" {
    value = "${data.aws_ami.default_ami.id}"
}



/*
    Security groups for EC2 containers
*/

# Internet facing rules
resource "aws_security_group" "openshift" {
    name = "openshift"
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 8443
        to_port = 8443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}



/*
    Create the master EC2 instance
*/

resource "aws_instance" "openshift" {
    ami = "${data.aws_ami.default_ami.id}"
    instance_type = "${var.aws_instance_size}"
    root_block_device {
        volume_type = "gp2"
        volume_size = 20
    }
    key_name = "openshift"
    security_groups = [ "${aws_security_group.openshift.name}" ]
    user_data = "${
        replace(
            replace(
                "${file("provision.sh")}",
                "<USERNAME>",
                "${var.openshift_username}"
            ),
            "<PASSWORD>",
            "${var.openshift_password}"
        )
    }"
}



/*
    Assign a static Public IP
*/

resource "aws_eip" "external_ip" {
    instance = "${aws_instance.openshift.id}"
}

# Store it as variable
output "public_ip" {
    value = "${aws_eip.external_ip.public_ip}"
}



/*
    Key to access the EC2 instances
*/

resource "aws_key_pair" "aws_pubkey" {
    key_name = "openshift"
    public_key = "${var.aws_public_key}"
}
