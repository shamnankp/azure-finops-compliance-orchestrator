import os
from collections import Counter
from flask import Flask, render_template_string
from azure.identity import DefaultAzureCredential
from azure.cosmos import CosmosClient

app = Flask(__name__)

client = CosmosClient(os.environ["COSMOS_ENDPOINT"], credential=DefaultAzureCredential())
container = client.get_database_client(os.environ["COSMOS_DB"]).get_container_client(os.environ["COSMOS_CONTAINER"])

PAGE = """
<!doctype html><title>FinOps Compliance Dashboard</title>
<style>
body{font-family:Segoe UI,Arial;margin:30px;background:#f4f6f8}
.cards{display:flex;gap:16px;margin-bottom:24px}
.card{background:#fff;padding:16px 24px;border-radius:8px;box-shadow:0 1px 3px #0002}
.card b{font-size:28px;display:block}
table{border-collapse:collapse;width:100%;background:#fff}
th,td{padding:8px 12px;border-bottom:1px solid #ddd;text-align:left;font-size:14px}
th{background:#0078d4;color:#fff}
</style>
<h1>FinOps Compliance Dashboard</h1>
<div class="cards">
<div class="card"><b>{{ total }}</b>Total records</div>
{% for k,v in actions.items() %}<div class="card"><b>{{ v }}</b>{{ k }}</div>{% endfor %}
</div>
<table><tr><th>Time (UTC)</th><th>Resource</th><th>Violation</th><th>Action</th><th>Status</th></tr>
{% for r in rows %}<tr><td>{{ r.timestamp[:19] }}</td><td>{{ r.resourceId.split('/')[-1] }}</td><td>{{ r.violation }}</td><td>{{ r.action }}</td><td>{{ r.status }}</td></tr>{% endfor %}
</table>
"""

@app.route("/")
def home():
    rows = list(container.query_items(
        query="SELECT TOP 100 * FROM c ORDER BY c.timestamp DESC",
        enable_cross_partition_query=True))
    return render_template_string(PAGE, rows=rows, total=len(rows),
                                  actions=Counter(r["action"] for r in rows))
