# Lab: GKE Autopilot + observabilidade completa (Prometheus, Grafana, Loki) 

Mini-projeto de estudo pra montar, do zero: cluster Kubernetes gerenciado, tráfego exposto via Load Balancer + DNS, observabilidade completa (métricas + logs).

⚠️ **Sobre custo**: o cluster GKE Autopilot em si é coberto pelo crédito
gratuito do Google (~$74/mês, cobre a taxa de gerenciamento). O que **não**
é coberto: o Load Balancer criado a partir do Ingress (~$0.025/hora, fixo,
existindo ou não tráfego) e os pods rodando (cobrado por CPU/memória
solicitada). **Destrua o Load Balancer entre sessões de estudo** - o
cluster pode ficar de pé sem problema.

## Progresso

- [x] **1. Cluster GKE Autopilot** - `terraform/` (VPC dedicada + cluster)
- [x] 2. Conectar e validar o cluster
- [x] 3. Primeiro app, sem expor pra internet - `k8s/01-hello-app.yaml`
- [x] 4. Expor via Ingress + Load Balancer + DNS (Cloudflare) - `terraform/dns.tf` + `k8s/02-ingress.yaml`
- [x] 5. Prometheus + Grafana (kube-prometheus-stack via Helm) - `helm/prometheus-values.yaml`
- [x] 6. Loki + Alloy (logs) - `helm/loki-values.yaml` + `helm/alloy-values.yaml`

## Pré-requisitos

- Terraform instalado
- `gcloud` autenticado
- `kubectl` instalado
- Helm instalado

## Passo 1 - Cluster

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# confere o project_id

terraform init
terraform apply
```

## Passo 2 - Conectar

```bash
terraform output -raw get_credentials_command
# copia e roda o comando que sair

kubectl get nodes
```

Cluster Autopilot recém-criado costuma vir sem nodes visíveis até o
primeiro pod ser agendado - isso é esperado.

## Passo 3 - Primeiro app

```bash
kubectl apply -f ../k8s/01-hello-app.yaml
kubectl get pods -n demo-apps
```

Ainda sem Ingress - só confirma que o app sobe (`Running`, 1/1 pod).

## Passo 4 - Ingress + Load Balancer + DNS

⚠️ A partir daqui o Load Balancer começa a custar (~$0.025/hora, fixo).

Precisa de duas informações da Cloudflare antes:
- **API Token**: perfil > API Tokens > Create Token > Custom Token, com
  permissão `Zone:DNS:Edit` só na zona do seu domínio (não usar token de
  conta inteira)
- **Zone ID**: aparece embutido no próprio JSON do token criado
  (`com.cloudflare.api.account.zone.<zone_id>`), ou na página da zona,
  card de Overview

```bash
cd terraform
# adiciona ao terraform.tfvars:
#   cloudflare_api_token = "..."
#   cloudflare_zone_id   = "..."

terraform apply
```

Isso cria o IP fixo e o registro DNS (mantenha `proxied = false` na
Cloudflare - nuvem cinza, não laranja - senão o certificado do Google não
consegue validar o domínio). Depois aplica o Ingress:

```bash
kubectl apply -f ../k8s/02-ingress.yaml
```

O certificado gerenciado pode levar 15-60 minutos pra ficar `Active`:

```bash
kubectl describe managedcertificate hello-app-cert -n demo-apps
```

## Passo 5 - Prometheus + Grafana

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack 
  --namespace monitoring --create-namespace 
  -f ../helm/prometheus-values.yaml

kubectl apply -f ../k8s/03-metrics-demo-app.yaml
kubectl apply -f ../k8s/04-servicemonitor.yaml
```

Acesso ao Grafana **sem criar um segundo Load Balancer** (evita outro
custo de ~$18/mês):

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

`localhost:3000`, login `admin` / senha definida em `prometheus-values.yaml`.

⚠️ **GKE Autopilot bloqueia vários componentes padrão desse chart** - o
`prometheus-values.yaml` já vem ajustado pra isso, mas vale entender por quê
(seção de notas no final deste README).

## Passo 6 - Loki + Alloy (logs)

Promtail (o agente clássico) **chegou ao fim da vida em março de 2026** e,
além disso, usa hostPath incompatível com o Autopilot - por isso usamos
**Grafana Alloy** aqui, o sucessor oficial.

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm install loki grafana/loki --namespace monitoring -f ../helm/loki-values.yaml
helm install alloy grafana/alloy --namespace monitoring -f ../helm/alloy-values.yaml

kubectl apply -f ../k8s/05-loki-grafana-datasource.yaml
```

Testar: no Grafana (mesmo port-forward do passo 5) → **Explore** →
datasource **Loki** → query `{namespace="demo-apps"}`.


## Passo 7 - Destruir o Load Balancer entre sessões

```bash
kubectl delete -f ../k8s/02-ingress.yaml
```

O cluster pode continuar de pé (é grátis). Só o Ingress/Load Balancer
precisa sair quando você não estiver estudando ativamente.

---

## Notas: incompatibilidades do GKE Autopilot (vale a leitura)

O Autopilot é bem mais restritivo que um GKE Standard comum - várias
ferramentas populares de observabilidade assumem acesso que ele não permite.
Isso consumiu boa parte do tempo desse lab, documentando aqui pra referência
futura:

- **Sem acesso a `/proc`, `/sys`, nem hostNetwork/hostPID** - por isso o
  `node-exporter` do kube-prometheus-stack e o `promtail` clássico não
  funcionam sem modificação (e no caso do Promtail, nem dá pra modificar -
  o caminho crítico está fixo no template do chart, não é configurável).
- **`kube-system` é um namespace gerenciado** - nada pode editar recursos
  lá dentro (por isso `coreDns`/`kubeDns` do kube-prometheus-stack precisam
  ficar desligados).
- **Autopilot aplica requests de CPU/memória "default" generosos** em
  qualquer container sem `resources` explícito - isso pode consumir a cota
  de CPU da conta sem aviso. Sempre definir `resources.requests` em tudo.
- **`kubectl top` mostra uso real, não reserva** - o agendador decide com
  base nos `requests` somados, não no uso de fato. Um node pode aparecer
  "livre" no `top` e mesmo assim recusar um pod novo.
- **`extraVolumes`/`extraVolumeMounts` variam de chart pra chart** - às
  vezes são raiz do `values.yaml`, às vezes aninhados por componente
  (ex: `singleBinary.extraVolumes` no chart do Loki). Sempre conferir a
  doc oficial da versão exata do chart antes de assumir a estrutura.

