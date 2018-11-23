resource "aws_vpc" "openshift" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags {
    Name    = "${var.name_tag_prefix} VPC"
    Project = "openshift"
  }
}

resource "aws_internet_gateway" "openshift" {
  vpc_id = "${aws_vpc.openshift.id}"

  tags {
    Name    = "${var.name_tag_prefix} IGW"
    Project = "openshift"
  }
}

resource "aws_subnet" "public-subnet" {
  vpc_id                  = "${aws_vpc.openshift.id}"
  cidr_block              = "${var.subnet_cidr}"
  availability_zone       = "${lookup(var.subnetaz[count.index], "az")}"
  map_public_ip_on_launch = true
  depends_on              = ["aws_internet_gateway.openshift"]

  tags {
    Name    = "${var.name_tag_prefix} Public Subnet"
    Project = "openshift"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.openshift.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.openshift.id}"
  }

  tags {
    Name    = "${var.name_tag_prefix} Public Route Table"
    Project = "openshift"
  }
}

//  Now associate the route table with the public subnet - giving
//  all public subnet instances access to the internet.
resource "aws_route_table_association" "public-subnet" {
  subnet_id      = "${aws_subnet.public-subnet.id}"
  route_table_id = "${aws_route_table.public.id}"
}
