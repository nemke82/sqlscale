variable "dbreplica_count" {
  description = "The replica count for the database volume"
  default     = 2
}

variable "screplica_count" {
  description = "The replica count for the sc and cspc"
  default     = 3
}


variable "node_count" {
  description = "Node count of EKS Cluster"
  default     = 3
}

variable "disk_size" {
  description = "The size of the disk for the operating system volume"
  default     = "10Gi"
}

variable "volume_size" {
  description = "The size of the disk for the database volume"
  default     = "10"
}

variable "node_availability_zones" {
  description = "List of availability zones in which nodes will be created"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"] # Define offered area zones
}


variable "openebs_namespace" {
  description = "The namespace where OpenEBS is deployed"
  default     = "openebs"
}

variable "database_namespace" {
  description = "The namespace for the database deployment"
  default     = "database"
}

variable "blockdevice_list" {
  description = "List of block device CRs for the cStor pool"
  type        = list(string)
  default     = ["blockdevice-1", "blockdevice-2", "blockdevice-3"]
}
