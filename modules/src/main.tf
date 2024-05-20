#######ネットワーク関連#######
# VPC
data "aws_vpc" "vpc" {
  id = "vpc-069f656ea9de1a173"
}

# サブネット
data "aws_subnet" "subnet_a" {
  id = "subnet-0813446eda2ab1d8e"
}

data "aws_subnet" "subnet_b" {
  id = "subnet-0bbf03a5ca6653d46"
}

data "aws_subnet" "subnet_c" {
  id = "subnet-029983d62d52dde8a"
}

data "aws_subnet" "public_subnet_a" {
  id = "subnet-0842ee2071bb1093a"
}

# インターネットゲートウェイ
resource "aws_internet_gateway" "main" {
  vpc_id = data.aws_vpc.vpc.id
  tags = {
    name = "sample-internet-gateway"
  }
}

# ルートテーブル
data "aws_route_table" "main" {
  route_table_id = "rtb-0ad75363c371989ca"
}

# ルートテーブル
data "aws_route_table" "public" {
  route_table_id = "rtb-0b44ac3933a945d1c"
}

# ルート
resource "aws_route" "main" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = data.aws_route_table.main.id
  gateway_id             = aws_internet_gateway.main.id

}

# ルートテーブルとの紐づけ
resource "aws_route_table_association" "public_1a" {
  subnet_id      = data.aws_subnet.subnet_a.id
  route_table_id = data.aws_route_table.main.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = data.aws_subnet.subnet_b.id
  route_table_id = data.aws_route_table.main.id
}

resource "aws_route_table_association" "public_1d" {
  subnet_id      = data.aws_subnet.subnet_c.id
  route_table_id = data.aws_route_table.main.id
}

resource "aws_route_table_association" "public_sample_1d" {
  subnet_id      = data.aws_subnet.public_subnet_a.id
  route_table_id = data.aws_route_table.public.id
}

resource "aws_eip" "sample_eip" {
  vpc = true

  tags = {
    Name = "terraform-sample-eip"
  }
}

resource "aws_nat_gateway" "sample_nat_gateway" {
  allocation_id = aws_eip.sample_eip.id
  subnet_id     = data.aws_subnet.public_subnet_a.id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = []
}
