resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name = "nat"
  }
}

resource "aws_nat_gateway" "k8s-nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-us-east-1a.id

  tags = {
    Name = "k8s-nat"
  }

  depends_on = [aws_internet_gateway.k8svpc-igw]
}

#resource "aws_nat_gateway" "k8s-lz-nat" {
#  allocation_id = aws_eip.nat.id
#  subnet_id     = aws_subnet.public-us-east-1-atl-2a.id
#
#  tags = {
#    Name = "k8s-nat"
#  }
#
#  depends_on = [aws_internet_gateway.k8svpc-igw]
#}
