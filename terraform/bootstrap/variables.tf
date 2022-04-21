variable "pool" {
  description = "The name of the rocketpool installation. This must match your vars directory name."
  type        = string
  default     = ""
  validation {
    condition     = length(var.pool) > 0
    error_message = "Must specify a rocketpool installation name."
  }
}
