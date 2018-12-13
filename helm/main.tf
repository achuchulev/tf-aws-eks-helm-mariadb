provider "helm" {
  service_account = "tiller"
  install_tiller  = true

  kubernetes {
  }
}

resource "helm_release" "my_database" {
  name      = "my-datasase"
  chart     = "stable/mariadb"

  set {
    name  = "mariadbUser"
    value = "foo"
  }

  set {
    name = "mariadbPassword"
    value = "qux"
  }
}
