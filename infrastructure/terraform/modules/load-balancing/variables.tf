variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "application_subnet_id" {
  description = "ID of the application tier subnet"
  type        = string
}

variable "presentation_subnet_id" {
  description = "ID of the presentation tier subnet"
  type        = string
}

variable "app_gateway_subnet_id" {
  description = "ID of the application gateway subnet"
  type        = string
  default     = null
}

variable "create_application_gateway" {
  description = "Whether to create an application gateway"
  type        = bool
  default     = true
}

variable "enable_https_listener" {
  description = "Whether to enable HTTPS listener on application gateway"
  type        = bool
  default     = false
}

variable "application_gateway_name" {
  description = "Name of the application gateway"
  type        = string
}

variable "application_gateway_public_ip_name" {
  description = "Name of the application gateway public IP"
  type        = string
}

variable "application_gateway_sku_name" {
  description = "SKU name for the application gateway"
  type        = string
  default     = "Standard_v2"
}

variable "application_gateway_sku_tier" {
  description = "SKU tier for the application gateway"
  type        = string
  default     = "Standard_v2"
}

variable "application_gateway_capacity" {
  description = "Capacity for the application gateway"
  type        = number
  default     = 1
}

variable "application_gateway_min_capacity" {
  description = "Minimum capacity for autoscaling"
  type        = number
  default     = 1
}

variable "application_gateway_max_capacity" {
  description = "Maximum capacity for autoscaling"
  type        = number
  default     = 2
}

variable "enable_app_gateway_autoscaling" {
  description = "Whether to enable autoscaling for application gateway"
  type        = bool
  default     = false
}

variable "application_gateway_backend_port" {
  description = "Backend port for application gateway"
  type        = number
  default     = 3000
}

variable "application_gateway_backend_https_port" {
  description = "Backend HTTPS port for application gateway"
  type        = number
  default     = 3000
}

variable "application_gateway_probe_path" {
  description = "Health probe path for application gateway"
  type        = string
  default     = "/"
}

variable "create_internal_lb" {
  description = "Whether to create an internal load balancer"
  type        = bool
  default     = true
}

variable "internal_lb_name" {
  description = "Name of the internal load balancer"
  type        = string
}

variable "internal_lb_private_ip" {
  description = "Private IP address for the internal load balancer"
  type        = string
}

variable "internal_lb_probe_path" {
  description = "Health probe path for the internal load balancer"
  type        = string
  default     = "/api/health"
}

variable "internal_lb_frontend_port" {
  description = "Frontend port for the internal load balancer"
  type        = number
  default     = 80
}

variable "internal_lb_backend_port" {
  description = "Backend port for the internal load balancer"
  type        = number
  default     = 8000
}

variable "internal_lb_probe_port" {
  description = "Health probe port for the internal load balancer"
  type        = number
  default     = 8000
}

variable "enable_internal_https_rule" {
  description = "Whether to enable HTTPS rule for internal load balancer"
  type        = bool
  default     = false
}

variable "enable_nat_pool" {
  description = "Whether to enable NAT pool for SSH access"
  type        = bool
  default     = true
}

variable "nat_pool_frontend_port_start" {
  description = "Start port for NAT pool"
  type        = number
  default     = 50000
}

variable "nat_pool_frontend_port_end" {
  description = "End port for NAT pool"
  type        = number
  default     = 50010
}

variable "nat_pool_backend_port" {
  description = "Backend port for NAT pool"
  type        = number
  default     = 22
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

