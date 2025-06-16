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
  }

  #using tuple/list to print multi vars
  #value = [var.name, var.phone_number, var.isMarried]
}