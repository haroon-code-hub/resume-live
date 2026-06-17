output "server_ip" {
  description = "Public IP address of the k3s server"
  value       = aws_eip.k3s.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the server"
  value       = "ssh ubuntu@${aws_eip.k3s.public_ip}"
}

output "kubectl_config_command" {
  description = "Command to fetch kubeconfig from the server"
  value       = "ssh ubuntu@${aws_eip.k3s.public_ip} 'sudo cat /etc/rancher/k3s/k3s.yaml' | sed 's/127.0.0.1/${aws_eip.k3s.public_ip}/g' > ~/.kube/resume-live-config"
}
