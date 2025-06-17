output "print_name_var" {
  #Using map to print multiple variables
  value = {
    name = var.name
    phone_number = var.phone_number
    isMarried = var.isMarried
    like_foods = var.like_foods
    like_numbers = var.like_numbers
    like_bools = var.like_bools
    like_object = var.like_object
    list_of_maps = var.list_of_maps
    list_of_sets_like = var.list_of_sets_like
    list_of_tuples = var.list_of_tuples
    set_strings = var.set_strings
    map_ex = var.map_ex
    tuple_ex = var.tuple_ex #This will print all values
    tuple_ex1 = var.tuple_ex[0] #This will print only first value
    obj_ex = var.obj_ex
  }

  

  #using tuple/list to print multi vars
  #value = [var.name, var.phone_number, var.isMarried]
}

output "keyValueExpressionUse" {
  value = {
    for t in var.set_strings:
    t => "Enabled" #=> expression is used to define key-value pairs
  }
}