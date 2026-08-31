# k8s/ - manifests com Kustomize

Estrutura:
- `base/` - a definicao "crua" de cada app/recurso, sem nada especifico
  de ambiente. Nunca aplica direto.
- `overlays/<ambiente>/` - referencia os bases e aplica customizacoes
  (labels, tag de imagem). E isso que voce aplica de verdade.

## Aplicar (dev)

```bash
kubectl apply -k overlays/dev
```

## Ver o resultado final sem aplicar (bom pra revisar antes)

```bash
kubectl kustomize overlays/dev
```

## Trocar a tag da imagem da orders-api sem editar o YAML na mao

```bash
cd overlays/dev
kustomize edit set image southamerica-east1-docker.pkg.dev/postgres-observability/lab-images/orders-api=southamerica-east1-docker.pkg.dev/postgres-observability/lab-images/orders-api:SEU_SHA_AQUI
kubectl apply -k .
```

## Adicionar um ambiente novo (ex: staging)

```bash
mkdir -p overlays/staging
# copia o kustomization.yaml do dev e ajusta o que for diferente
# (nome do dominio no ingress, replicas, etc via patches)
```
