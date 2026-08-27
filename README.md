# Lab: GKE Autopilot + observabilidade completa (Prometheus, Grafana, Loki) + ArgoCD

Mini-projeto de estudo pra montar, do zero: cluster Kubernetes gerenciado, tráfego exposto via Load Balancer + DNS, observabilidade completa (métricas + logs) e deploys via GitOps.

⚠️ **Sobre custo**: o cluster GKE Autopilot em si é coberto pelo crédito
gratuito do Google (~$74/mês, cobre a taxa de gerenciamento). O que **não**
é coberto: o Load Balancer criado a partir do Ingress (~$0.025/hora, fixo,
existindo ou não tráfego) e os pods rodando (cobrado por CPU/memória
solicitada). **Destrua o Load Balancer entre sessões de estudo** - o
cluster pode ficar de pé sem problema.

## Progresso

- [x] **1. Cluster GKE Autopilot** - `terraform/` (VPC dedicada + cluster)
- [ ] 2. Conectar e validar o cluster
- [x] 3. Primeiro app, sem expor pra internet - `k8s/01-hello-app.yaml` (pronto pra aplicar)
- [ ] 4. Expor via Ingress + Load Balancer + DNS (Cloudflare)
- [ ] 5. Prometheus + Grafana (kube-prometheus-stack via Helm)
- [ ] 6. Loki + Promtail (logs)
- [ ] 7. ArgoCD (fecha o ciclo GitOps)
- [ ] 8. Rotina de destruir o Load Balancer entre sessões

## Pré-requisitos

- Terraform instalado
- `gcloud` autenticado
- `kubectl` instalado

## Passo 1 - Cluster

​```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# confere o project_id

terraform init
terraform apply
​```

## Passo 2 - Conectar

​```bash
terraform output -raw get_credentials_command
# copia e roda o comando que sair

kubectl get nodes
​```

Cluster Autopilot recém-criado costuma vir sem nodes visíveis até o
primeiro pod ser agendado - isso é esperado.

## Passo 3 - Primeiro app

​```bash
kubectl apply -f ../k8s/01-hello-app.yaml
kubectl get pods -n demo-apps
​```

Ainda sem Ingress - só confirma que o app sobe (`Running`, 2/2 pods).