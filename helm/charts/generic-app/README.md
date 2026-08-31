# generic-app

Chart reutilizavel pros apps simples do lab. Nao usar pra apps com estado
(banco de dados, etc) - esses continuam como manifests normais em `k8s/`.

## Values principais

| Chave | Descricao |
|---|---|
| `image.repository` / `image.tag` | Imagem do container |
| `containerPort` | Porta que o container escuta |
| `env` | Lista de env vars (suporta `value` e `valueFrom.secretKeyRef`) |
| `probes.enabled` | Liga readiness/liveness probes em `/readyz` e `/healthz` |
| `service.port` / `service.targetPort` | Porta do Service |
| `serviceMonitor.enabled` | Cria um ServiceMonitor pro Prometheus raspar `/metrics` |
| `ingress.enabled` + `ingress.host` + `ingress.staticIpName` | Cria Ingress + ManagedCertificate (GKE) |

## Testar localmente sem instalar

```bash
helm template minha-app . -f ../../apps/hello-app/values-dev.yaml
```
