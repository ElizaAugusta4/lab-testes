# helm

Charts Helm proprios (nao charts de terceiros - esses ficam so
referenciados por `chart:`/`repoURL` direto nas Applications do
`argo-applications/`, sem copiar codigo pro nosso repo).

## Charts

- `generic-app/` - reutilizavel pra apps simples sem estado (hello-app,
  orders-api, metrics-demo). Segue o padrao oficial do scaffold do Helm
  (`labels`/`selectorLabels` separados, `NOTES.txt`, `ServiceAccount`
  opcional).
- `postgres/` - banco de dados do lab. Simples, sem HA, sem persistencia
  real por padrao (`persistence.enabled: false`).

## Testar um chart sem instalar

```bash
cd generic-app
helm template minha-app . -f ../../application-manifests/dev/demo-apps/hello-app/values.yaml
```

## Onde ficam os values de cada app

Nao aqui - em `application-manifests/`. Esse repo so tem os *templates*,
nunca valores especificos de app ou ambiente.
