# Incidentes - Documentação

- [ ] **Cota de CPU da região esgotada bloqueando scale-up** - autoscaler
      tentando criar node novo, `GCE quota exceeded`, pod preso em `Pending`
      mesmo com nodes existentes com folga de uso real (`kubectl top` baixo)
- [ ] **ServiceMonitor sem dado nenhum, silenciosamente** - Prometheus
      "encontra" o ServiceMonitor mas mostra `0/0 up`, sem erro nenhum -
      só pela ausência do pod-alvo
- [ ] **Chart do Helm gerando erro de política do Autopilot** - hostPath
      proibido (node-exporter, promtail) - dá pra simular de novo com
      qualquer chart que assuma acesso de node "tradicional"
- [ ] **Aplicação crashando por falta de volume gravável** - `read-only
      file system` no Loki, por causa de `persistence.enabled: false`
      sem um volume alternativo

## App-level

- [ ] **CrashLoopBackOff por variável de ambiente faltando** - a
      aplicação espera uma env var obrigatória, não recebe, morre no boot
- [ ] **OOMKilled** - o `limits.memory` abaixo do
      necessário, pod morre e reinicia em loop
- [ ] **ImagePullBackOff** - tag de imagem que não existe
- [ ] **Readiness probe mal configurada** - probe aponta pra porta/path
      errado, pod fica `Running` mas nunca `Ready`, Service nunca manda
      tráfego pra ele
- [ ] **Rollout travado** - nova versão do Deployment nunca fica pronta,
      versão antiga vai sendo substituída aos poucos até não sobrar
      nenhuma réplica saudável

## Cluster / Kubernetes

- [ ] **"Too many pods" num node** - Autopilot tem um limite de pods por
      node; empilhar réplicas pequenas até bater nesse teto
- [ ] **PodDisruptionBudget bloqueando manutenção** - configurar um PDB
      exigente demais e ver o GKE não conseguir fazer upgrade de node
- [ ] **Falta de PodDisruptionBudget** - o oposto: sem PDB, uma
      manutenção de node pode derrubar todas as réplicas de uma vez

## Rede / Ingress / DNS

- [ ] **Certificado gerenciado nunca fica Active** - ligar o proxy da
      Cloudflare (nuvem laranja) de propósito e ver a validação do Google
      falhar
- [ ] **502 do Load Balancer com backend "saudável"** - Service apontando
      pra porta errada do container

## Observabilidade (a própria stack falhando)

- [ ] **Prometheus fica sem dado histórico** - `retention: 6h` -
      investigar algo que aconteceu há 7h atrás, modificar a propriedade
      de retention
- [ ] **Grafana "esquece" datasource/dashboard depois de reiniciar** -
      consequência direta de `persistence.enabled: false`
- [ ] **Alerta que nunca dispara** - o Alertmanager está desabilitado

## Custo / FinOps

- [ ] **Load Balancer esquecido rodando** - deletar o Ingress e ver o LB
      sumir, comparando o tempo/custo de ter deixado rodando à toa
- [ ] **Autopilot aplicando "defaults" caros sem avisar** - o
      `kube-state-metrics` (2Gi de memória default)

## App-level (novo, com a orders-api + Postgres)

- [ ] **403 no pull de imagem por falta de IAM** - a service account dos
      nodes não tinha `artifactregistry.reader`, mesmo com a imagem existindo
      no repositório certo
- [ ] **Banco perde todos os dados no restart** - `postgres` sem volume
      persistente (emptyDir); reiniciar o pod e ver a tabela `orders` sumir
- [ ] **Connection pool esgotado** - a API tem um pool de só 10 conexões;
      gerar tráfego concorrente demais e ver requests travarem esperando
      conexão livre
- [ ] **Query lenta visível nos dois sistemas** - o `/orders` tem 10% de
      chance de simular lentidão; achar isso tanto pelo histograma no
      Prometheus quanto pelo log de `duration_ms` alto no Loki