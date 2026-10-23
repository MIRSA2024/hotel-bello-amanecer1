variable "db_subnet_ids" {
  description = "Subredes aisladas de la BD (lo escribe el módulo network)"
  type        = list(string)
}

variable "sg_db_id" {
  description = "Security Group de la BD (lo escribe el módulo security)"
  type        = string
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_multi_az" {
  description = "Multi-AZ según el diseño. Poner false solo si el laboratorio lo rechaza."
  type        = bool
  default     = true
}

variable "db_deletion_protection" {
  description = "Protección contra borrado (diseño: true). destroy.sh la desactiva antes de destruir."
  type        = bool
  default     = true
}

variable "db_skip_final_snapshot" {
  description = "Diseño: false (se toma snapshot final). destroy.sh lo pone en true para limpiar el laboratorio."
  type        = bool
  default     = false
}

variable "use_managed_master_password" {
  description = "true = RDS crea y administra el secreto. false = Terraform genera la clave y la guarda en Secrets Manager (plan B del laboratorio)."
  type        = bool
  default     = true
}
