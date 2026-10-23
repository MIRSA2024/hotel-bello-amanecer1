variable "vpc_id" {
  description = "ID de la VPC (lo escribe el módulo network)"
  type        = string
}

variable "db_subnet_ids" {
  description = "Subredes aisladas de la base de datos (lo escribe el módulo network)"
  type        = list(string)
}

variable "app_cidrs" {
  description = "Rangos de las subredes de aplicación que pueden hablar con la BD"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}
