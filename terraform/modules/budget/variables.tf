variable "project_name" { type = string }
variable "environment"  { type = string }

variable "email" {
  type        = string
  description = "Email to notify when budget threshold is exceeded."
}

variable "limit_amount" {
  type        = string
  description = "Monthly budget in USD."
  default     = "5"
}

variable "threshold_percent" {
  type        = number
  description = "Percent of budget that triggers alert."
  default     = 80
}
