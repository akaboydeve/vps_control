from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import psutil, platform, socket, datetime, time, os, subprocess
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

origins = [
    "https://vps-control-web.vercel.app",
    "https://vps-control-web.hexonode.com",
    "http://localhost:3000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

API_TOKEN = os.getenv("API_TOKEN", "fallback_token")

def get_os_info():
    try:
        if os.path.exists("/etc/os-release"):
            with open("/etc/os-release") as f:
                lines = f.readlines()
            for line in lines:
                if line.startswith("PRETTY_NAME"):
                    return line.split("=")[1].strip().strip('"')
        return platform.system()
    except:
        return platform.system()

def get_system_info():
    os_name = get_os_info()
    hostname = socket.gethostname()
    cpu_usage = psutil.cpu_percent(interval=1)
    mem = psutil.virtual_memory()
    ram_total = round(mem.total / (1024 ** 3), 2)
    ram_used = round(mem.used / (1024 ** 3), 2)
    ram_percent = mem.percent
    disk = psutil.disk_usage('/')
    disk_percent = disk.percent
    boot_time = datetime.datetime.fromtimestamp(psutil.boot_time())
    uptime = datetime.datetime.now() - boot_time
    net1 = psutil.net_io_counters()
    time.sleep(1)
    net2 = psutil.net_io_counters()
    net_in = (net2.bytes_recv - net1.bytes_recv) / 1024
    net_out = (net2.bytes_sent - net1.bytes_sent) / 1024

    return {
        "os_name": os_name,
        "hostname": hostname,
        "cpu_usage": f"{cpu_usage}%",
        "ram_used": f"{ram_used} GB",
        "ram_total": f"{ram_total} GB",
        "ram_percent": f"{ram_percent}%",
        "disk_percent": f"{disk_percent}%",
        "uptime": str(uptime).split('.')[0],
        "network_in_kbps": round(net_in, 2),
        "network_out_kbps": round(net_out, 2),
    }

def authorize(request: Request):
    auth_header = request.headers.get("authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Unauthorized")
    token = auth_header.split(" ")[1]
    if token != API_TOKEN:
        raise HTTPException(status_code=403, detail="Forbidden")

@app.get("/status")
async def status(request: Request):
    authorize(request)
    return JSONResponse(content=get_system_info())

@app.post("/reboot")
async def reboot(request: Request):
    authorize(request)
    try:
        subprocess.Popen(["sudo", "reboot"])
        return {"status": "Reboot command issued"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
