# helm/ - values organizados por chart e ambiente

```
helm/values/<chart>/<ambiente>.yaml
```

## Instalar/atualizar (dev)

```bash
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  -f values/kube-prometheus-stack/dev.yaml

helm upgrade --install loki grafana/loki \
  --namespace monitoring \
  -f values/loki/dev.yaml

helm upgrade --install alloy grafana/alloy \
  --namespace monitoring \
  -f values/alloy/dev.yaml
```

## Adicionar um ambiente novo

```bash
cp values/kube-prometheus-stack/dev.yaml values/kube-prometheus-stack/staging.yaml
# ajusta o que for diferente (recursos, retention, etc)
```
