output "certificate" {
  value       = aws_iot_certificate.cert.certificate_pem
  description = "Certificate.pem file"
}

output "public_key" {
  value       = aws_iot_certificate.cert.public_key
  description = "public key file"
}

output "private_key" {
  value       = aws_iot_certificate.cert.private_key
  description = "private key file"
}