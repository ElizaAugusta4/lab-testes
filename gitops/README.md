# gitops/ - ArgoCD

A partir daqui, o ArgoCD passa a ser o unico responsavel por aplicar
mudancas no cluster. Depois de instalado, **pare de rodar `kubectl apply`,
`helm upgrade --install` e `kubectl apply -k` manualmente** - qualquer
mudanca deve ser feita editando os arquivos do repositorio (chart, values,
kustomize) e dando push. O ArgoCD detecta e sincroniza sozinho (config
`syncPolicy.automated` em cada Application).

## 1. Instalar o ArgoCD

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argocd argo/argo-cd \
  --namespace argocd --create-namespace \
  -f ../helm/values/argocd/dev.yaml
```

## 2. Acessar a UI (via port-forward, sem Load Balancer novo)

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

Pega a senha inicial do admin:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Abre `https://localhost:8080`, login `admin` + a senha acima.

## 3. Registrar o projeto e as Applications

```bash
kubectl apply -f argocd/project.yaml
kubectl apply -f argocd/apps/
```

Isso registra 7 Applications: `hello-app`, `orders-api`, `metrics-demo`,
`k8s-dev` (namespace + postgres + datasource do Loki), e a stack de
observabilidade inteira (`kube-prometheus-stack`, `loki`, `alloy`).

## 4. Acompanhar a sincronizacao

```bash
kubectl get applications -n argocd
```

Cada uma deve passar de `OutOfSync`/`Progressing` pra `Synced` + `Healthy`
em alguns minutos. Se alguma ficar presa, `kubectl describe application
<nome> -n argocd` mostra o motivo.

## Fluxo de trabalho daqui pra frente

1. Edita um values.yaml, um template do chart, ou um manifest do `k8s/base`
2. Commit + push
3. ArgoCD detecta a mudanca sozinho (por padrao, checa a cada ~3min) e
   aplica - ou forca uma sincronizacao manual: `argocd app sync <nome>`
   (via CLI do ArgoCD) ou pelo botao "Sync" na UI

Isso fecha o ciclo GitOps completo que vimos nos repositorios da empresa:
o Git e a unica fonte de verdade, ninguem mais roda `kubectl apply` a mao.
