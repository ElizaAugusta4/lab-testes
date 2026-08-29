# O provider "cloudflare" e configurado no environment (raiz), nao aqui -
# modulos nao devem configurar providers, so usar os recursos.

resource "cloudflare_dns_record" "this" {
  zone_id = var.zone_id
  name    = var.subdomain
  type    = "A"
  content = var.ip_address
  ttl     = 300
  proxied = false # nuvem cinza - necessario pro Google Managed Certificate validar o dominio
  comment = var.comment
}
