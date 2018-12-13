provider "kubernetes" {}

resource "kubernetes_storage_class" "gp2" {
  metadata {
    name = "gp2"
  }

  #https://kubernetes.io/docs/concepts/storage/storage-classes/#aws-ebs
  storage_provisioner = "kubernetes.io/aws-ebs"

  parameters {
    type      = "gp2"
    encrypted = "false"
  }
}
