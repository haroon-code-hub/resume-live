output "server_ip" {
  description = "Public IPv4 address of the server"
  value       = hcloud_server.resume_live.ipv4_address
}