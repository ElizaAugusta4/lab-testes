# argo-applications

As `Application` do ArgoCD - uma por app, por ambiente. Define QUAL
fonte (chart proprio, chart publico, ou Kustomize) e QUAIS values usar,
sem conter nenhum valor de configuracao em si (isso vive em
`application-manifests/`).

## Instalar o ArgoCD

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argocd argo/argo-cd \
  --namespace argocd --create-namespace \
  -f ../application-manifests/dev/argocd/values.yaml
```

## Acessar a UI

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

Senha inicial:
```bash
$senha = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($senha))
```

## Registrar o projeto e as Applications

```bash
kubectl apply -f ../application-manifests/argocd/projects/lab.yaml
kubectl apply -f dev/
```

## Sync waves (ordem de sincronizacao)

`postgres` sincroniza na wave `0`, `orders-api` na wave `1` - garante
que o banco (e o Secret de credenciais) existam antes da API tentar
conectar. Os outros apps nao tem dependencia entre si.

## Fluxo de trabalho

Editar `application-manifests/` ou `agriness-helm/` -> commit -> push ->
ArgoCD sincroniza sozinho. **Nunca** `kubectl apply`/`helm upgrade`
manual depois que o ArgoCD assumiu - isso gera drift que o proprio
ArgoCD desfaz na proxima sincronizacao.
