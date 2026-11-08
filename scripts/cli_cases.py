"""作者 Wangyuan，2026-10-29。对实际编译CLI执行合成正常/恶例。"""
import copy,json,subprocess,sys,tempfile
from pathlib import Path
binary=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else Path('.build/debug/planner').resolve()
def invoke(payload):
    with tempfile.TemporaryDirectory() as folder:
        path=Path(folder)/'synthetic.json';path.write_text(json.dumps(payload))
        return subprocess.run([str(binary),str(path)],text=True,capture_output=True)
def reject(payload):
    result=invoke(payload);assert result.returncode==2,(result.returncode,result.stdout,result.stderr);assert not result.stdout,result.stdout
base={"today":"2030-01-01","subscriptions":[{"name":"Synthetic","price":"10","currency":"USD","cycle":"weekly","first_bill":"2030-01-02"}]}
r=invoke(base);assert r.returncode==0,r.stderr;assert json.loads(r.stdout)["amount_due_this_month"]["USD"]=="50"
assert "含今天以前" in json.loads(r.stdout)["amount_due_this_month_notice"]
count=1
for amount in ["12junk","12\n","1e2","-1","NaN"]:
    p=copy.deepcopy(base);p["subscriptions"][0]["price"]=amount;reject(p);count+=1
for days in [None,0,-1]:
    p=copy.deepcopy(base);p["subscriptions"][0]["cycle"]="custom";p["subscriptions"][0]["custom_days"]=days;reject(p);count+=1
print(f"CLI cases passed: {count}")
