#output "mysql_service_ip" {
#  value = helm_release.mysql.status.load_balancer.ingress[0].ip
#  description = "The IP address of the MySQL service"
#}
