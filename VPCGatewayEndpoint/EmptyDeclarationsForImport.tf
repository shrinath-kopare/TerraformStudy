# # Step 1 - declare
# resource "aws_vpc" "my_vpc" {}

# resource "aws_subnet" "myPublicSubnet" {
# }

# resource "aws_subnet" "myPrivateSubnet" {

# }

# resource "aws_instance" "myBastionHost" {

# }   

# resource "aws_internet_gateway" "myIG" {

# }

# resource "aws_route_table" "myPublicRT" {

# }

# resource "aws_route_table" "myPrivateRT" {

# }

# resource "aws_vpc_endpoint" "myGatewayEndpoint" {

# }

# resource "aws_instance" "myPrivateInstance" {

# }  

# resource "aws_iam_role" "myS3Role" {
#   # Leave this empty for now
# }



# # Step 2 - import
# # terraform import aws_vpc.my_vpc vpc-0ab1234567cdef890

# # Step 3 - generate config
# # terraform show -no-color > vpc.tf