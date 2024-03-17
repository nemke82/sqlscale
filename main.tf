resource "null_resource" "fetch_bd_mappings" {
  depends_on = [
    helm_release.openebs_repo
  ]

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "${path.module}/fetch_bd_mappings.sh"
  }
}

data "external" "node_instance_ids" {
  program = ["bash", "${path.module}/fetch_instance_ids.sh"]
}

output "raw_script_output" {
  value = data.external.node_instance_ids.result
}

output "instance_ids" {
  value = [for instance in local.instances_data: instance.id]
}

output "availability_zones" {
  value = {for instance in local.instances_data: instance.id => instance.availability_zone}
}

provider "kubernetes" {
  config_path = "~/.kube/config"
  # Alternatively, you can specify the host, client_certificate, client_key, and cluster_ca_certificate directly.
  # Make sure to replace "~/.kube/config" with the path to your actual kubeconfig file if it's located elsewhere.
}

resource "kubernetes_namespace" "openebs" {
  metadata {
    name = var.openebs_namespace
  }
}

resource "kubernetes_namespace" "database" {
  metadata {
    name = var.database_namespace
  }
}

resource "aws_ebs_volume" "data" {
  count             = length(local.instance_ids_list)
  availability_zone = local.instance_azs_map[local.instance_ids_list[count.index]]
  size              = var.volume_size
  type              = "gp3"
}

locals {
  // Decode the JSON string into a Terraform list of maps. This assumes that the JSON structure
  // is an array of objects where each object contains an "id" and an "availability_zone".
  instances_data = jsondecode(data.external.node_instance_ids.result["instances"])

  // Create a list of instance IDs from the instances data
  instance_ids_list = [for instance in local.instances_data : instance.id]

  // Create a map of instance IDs to availability zones for easy lookup
  instance_azs_map = {for instance in local.instances_data : instance.id => instance.availability_zone}
}

resource "aws_volume_attachment" "data" {
  count        = length(local.instance_ids_list)
  device_name  = "/dev/sdh"  # Adjust as needed for your device naming scheme
  volume_id    = aws_ebs_volume.data[count.index].id
  instance_id  = local.instance_ids_list[count.index]
  force_detach = true
}

# Add the OpenEBS Helm repository
resource "helm_release" "openebs_repo" {
  depends_on = [kubernetes_namespace.openebs]
  name       = "openebs"
  repository = "https://openebs.github.io/charts"
  chart      = "openebs"
  version    = "3.4.0"
  namespace  = var.openebs_namespace

  set {
    name  = "cstor.enabled"
    value = "true"
  }

  lifecycle {
    ignore_changes = [
      set,
    ]
  }
}

resource "kubectl_manifest" "cstor_pool" {
  yaml_body = templatefile("${path.module}/cspc-template.yaml.tpl", {
    nodes = jsondecode(file("${path.module}/nodes.json"))
  })

  depends_on = [helm_release.openebs_repo, null_resource.fetch_bd_mappings]
}

resource "kubectl_manifest" "openebs_sc" {
  yaml_body = <<-YAML
  apiVersion: storage.k8s.io/v1
  kind: StorageClass
  metadata:
    name: cstor-csi-disk
  provisioner: cstor.csi.openebs.io
  allowVolumeExpansion: true
  parameters:
    cas-type: cstor
    cstorPoolCluster: cspc-disk-pool
    replicaCount: "${var.screplica_count}"
  YAML

  depends_on = [kubectl_manifest.cstor_pool,helm_release.openebs_repo, null_resource.fetch_bd_mappings]
}

resource "helm_release" "mysql" {
  name       = "mariadb"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mariadb"
  namespace  = var.database_namespace

  set {
    name  = "global.storageClass"
    value = "cstor-csi-disk"
  }

  set {
    name  = "primary.persistence.storageClass"
    value = "cstor-csi-disk"
  }

  set {
    name  = "secondary.persistence.storageClass"
    value = "cstor-csi-disk"
  }

  set {
    name  = "persistence.size"
    value = var.disk_size
  }

  set {
    name  = "replicaCount"
    value = var.dbreplica_count
  }

  depends_on = [kubectl_manifest.cstor_pool,kubectl_manifest.openebs_sc, kubernetes_namespace.database, helm_release.openebs_repo]
}

