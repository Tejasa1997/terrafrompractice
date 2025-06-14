output "public_ip" {
  value = aws_instance.pub_ec2.public_ip
}

output "public_dns" {
  value = aws_instance.pub_ec2.public_dns
}

output "private_dns" {
  value = aws_instance.pvt_ec2.private_dns
}

output "private_ip" {
  value     = aws_instance.pvt_ec2.private_ip
  sensitive = true
}

/*output "private_key_path" {
  value = local_file.private_key.filename
}
*/
