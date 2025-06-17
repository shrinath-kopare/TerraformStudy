#String variable
variable "name" {
    type = string
    default = "Shrinath"
    description = "test"
    nullable = false #Specify if the variable can be null within the module.
    sensitive = false #Limits Terraform UI output when the variable is used in configuration.
    validation {
      condition = var.name == "Shrinath" #more conditions: https://developer.hashicorp.com/terraform/language/expressions/custom-conditions#input-variable-validation
      error_message = "Name must be shrinath"
    } 
}

#Number variable
variable "phone_number" {
    type = number
    default = 9876543210
    description = "Phone"
}

#Bool variable
variable "isMarried" {
    type = bool
    default = true
    description = "Is married or not?"
}

#List var - string
variable "like_foods" {
    type = list(string)
    default = [ "mango", "banana" ]
}

#List var - numbers
variable "like_numbers" {
  type = list(number)
  default = [ 100, 200 ]
}

#List var - bool
variable "like_bools" {
    type = list(bool)
    default = [ true, false ]
}

#List var - Objects
variable "like_object" {
  type = list(object({
    name = string
    phone_number = number
  }))
  default = [ {
    name = "Shri"
    phone_number = 1234
  } ]
}

#List of map
variable "list_of_maps" {
  type = list(map(string))
  default = [
    { name = "Shrinath", city = "Pune" },
    { name = "Prashant", city = "Mumbai" }
  ]
}

# #This works but not discouraged in Terraform
# variable "list_of_sets_like1" {
#   type = list(set(string))
#   default = [ [ "Sample" ] ]
# }

#List of set
variable "list_of_sets_like" {
  type = list(object({
    values = set(string)
  }))
  default = [
    { values = ["a", "b", "c"] },
    { values = ["x", "y"] }
  ]
}

#List of tuple
variable "list_of_tuples" {
  type = list(tuple([string, number]))
  default = [
    ["alpha", 1],
    ["beta", 2]
  ]
}

#Set of strings
variable "set_strings" {
  type = set(string)
  default = [ "Cat", "Dog", "Dog" ] #It wont save Dog twice
}

#Map of strings
variable "map_ex" {
  type = map(string)
  default = {
    "name" = "Shri"
    "lastname" = "Kopare"
  }
}

#Tuple
variable "tuple_ex" {
  type = tuple([ string, number ])
  default = [ "Start", 100 ]
}

#Object
variable "obj_ex" {
  type = object({
    name = string
    phone_number = number
  })

  default = {
    name = "Shrinath"
    phone_number = 9876543210
  }
}