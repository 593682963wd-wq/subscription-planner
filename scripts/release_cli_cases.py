"""作者：Wangyuan；日期：2026-11-08。职责：实测当天续费提醒和CSV单独回车。"""
import csv
import io
import json
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as folder:
    path = Path(folder) / "synthetic.json"
    path.write_text(json.dumps({"today": "2030-01-02", "subscriptions": [{"name": "Alpha\rBeta", "price": "10", "currency": "USD", "cycle": "weekly", "first_bill": "2030-01-02", "reminders": [0]}]}))
    process = subprocess.run([str(root / ".build/debug/planner"), str(path)], text=True, capture_output=True, check=True)
    result = json.loads(process.stdout)
    assert result["reminder_plan"][0]["date"] == "2030-01-02"
    rows = list(csv.reader(io.StringIO(result["csv"], newline="")))
    assert len(rows) == 2 and rows[1][0] == "Alpha\rBeta"
print("2 release CLI cases passed")
