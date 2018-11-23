//  Create the master userdata script.
data "template_file" "setup-master" {
  template = "${file("${path.module}/files/setup-master.sh")}"
}

resource "aws_instance" "master" {
  ami                  = "${data.aws_ami.centos_7.id}"
  instance_type        = "m4.large"
  subnet_id            = "${aws_subnet.public-subnet.id}"
  iam_instance_profile = "${aws_iam_instance_profile.openshift-instance-profile.id}"
  user_data            = "${data.template_file.setup-master.rendered}"

  vpc_security_group_ids = [
    "${aws_security_group.openshift-vpc.id}",
    "${aws_security_group.openshift-public-ingress.id}",
    "${aws_security_group.openshift-public-egress.id}",
  ]

  root_block_device {
    volume_size = 50
    volume_type = "io1"
    iops        = 2500
  }

  # Storage for Docker, see:
  # https://docs.openshift.org/latest/install_config/install/host_preparation.html#configuring-docker-storage
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 50
    volume_type = "io1"
    iops        = 2500
  }

  key_name = "${var.key_name}"

  tags {
    Name    = "${var.name_tag_prefix} Master"
    Project = "openshift"
    owner   = "${var.owner}"
    TTL     = "${var.ttl}"
  }
}

//  Create the node userdata script.
data "template_file" "setup-node" {
  template = "${file("${path.module}/files/setup-node.sh")}"
}

resource "aws_instance" "node1" {
  ami                  = "${data.aws_ami.centos_7.id}"
  instance_type        = "${var.node_size}"
  subnet_id            = "${aws_subnet.public-subnet.id}"
  iam_instance_profile = "${aws_iam_instance_profile.openshift-instance-profile.id}"
  user_data            = "${data.template_file.setup-node.rendered}"

  vpc_security_group_ids = [
    "${aws_security_group.openshift-vpc.id}",
    "${aws_security_group.openshift-public-ingress.id}",
    "${aws_security_group.openshift-public-egress.id}",
  ]

  //  We need at least 30GB for OpenShift, let's be greedy...
  root_block_device {
    volume_size = 50
    volume_type = "io1"
    iops        = 2500
  }

  # Storage for Docker, see:
  # https://docs.openshift.org/latest/install_config/install/host_preparation.html#configuring-docker-storage
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = 50
    volume_type = "io1"
    iops        = 2500
  }

  key_name = "${var.key_name}"

  tags {
    Name    = "${var.name_tag_prefix} Node 1"
    Project = "openshift"
    owner   = "${var.owner}"
    TTL     = "${var.ttl}"
  }
}
