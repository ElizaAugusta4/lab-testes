from __future__ import annotations

import logging
import random
from datetime import datetime

import requests
from airflow.decorators import dag, task

# Service interno do Kubernetes - mesmo padrao de "DB_HOST=postgres" que
# usamos na orders-api: nome do Service, sem precisar de IP fixo nem DNS
# externo, porque tudo roda dentro do mesmo cluster.
ORDERS_API_URL = "http://orders-api.demo-apps.svc.cluster.local:8000"

CUSTOMERS = ["Ana", "Bruno", "Carla", "Diego", "Eliza", "Felipe"]

logger = logging.getLogger(__name__)


@dag(
    dag_id="orders_report",
    description="Gera um pedido sintetico e reporta o total por status - integra com a orders-api",
    schedule="*/10 * * * *",  # a cada 10 minutos
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["orders-api", "lab"],
)
def orders_report():
    """
    Duas tarefas encadeadas:
    1. Cria um pedido sintetico na orders-api (gera trafego real, visivel
       no Loki e no histograma de duracao de query no Prometheus).
    2. Le os ultimos pedidos e loga um relatorio simples de contagem por
       status - aparece no log da task, e o Alloy coleta junto com o
       resto dos logs do cluster.
    """

    @task
    def create_synthetic_order() -> str:
        customer = random.choice(CUSTOMERS)
        resp = requests.post(
            f"{ORDERS_API_URL}/orders",
            json={"customer": customer, "status": random.randint(0, 5)},
            timeout=10,
        )
        resp.raise_for_status()
        logger.info("Pedido criado pra %s: %s", customer, resp.json())
        return customer

    @task
    def report_orders_by_status(customer: str) -> None:
        resp = requests.get(f"{ORDERS_API_URL}/orders", params={"limit": 100}, timeout=10)
        resp.raise_for_status()
        orders = resp.json()

        counts: dict[int, int] = {}
        for order in orders:
            counts[order["status"]] = counts.get(order["status"], 0) + 1

        logger.info(
            "Relatorio - %d pedidos nos ultimos 100: %s (novo pedido foi de %s)",
            len(orders),
            counts,
            customer,
        )

    report_orders_by_status(create_synthetic_order())


orders_report()
