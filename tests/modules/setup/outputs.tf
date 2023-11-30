output "vpc_id" {
  value = module.vpc.vpc_id
}

output "subnet_id" {
  value = element(module.vpc.private_subnets, 0)
}
