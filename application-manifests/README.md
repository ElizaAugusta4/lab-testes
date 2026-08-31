# application-manifests

Values de cada app, por ambiente e namespace - a config "de fato" de
cada coisa que roda no cluster. Nenhuma logica aqui, so dados.

## Estrutura

```
dev/
├── demo-apps/              # namespace demo-apps
│   ├── hello-app/values.yaml
│   ├── orders-api/values.yaml
│   ├── postgres/values.yaml
│   └── metrics-demo/values.yaml
├── monitoring/              # namespace monitoring
│   ├── kube-prometheus-stack/values.yaml
│   ├── loki/values.yaml
│   └── alloy/values.yaml
└── argocd/values.yaml       # namespace argocd

argocd/
└── projects/
    └── lab.yaml              # AppProject - escopo do que a pipeline pode tocar
```

## Adicionar um app novo

1. Cria a pasta `dev/<namespace>/<nome-do-app>/values.yaml`
2. Se for usar o `generic-app`, referencia esse arquivo na Application
   correspondente em `argo-applications/dev/<nome-do-app>.yaml`

## Adicionar um ambiente novo (ex: staging)

```bash
cp -r dev staging
# ajusta os values (replicas, dominio, recursos, etc)
```
