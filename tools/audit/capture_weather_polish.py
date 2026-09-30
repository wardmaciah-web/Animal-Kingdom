"""Capture only the Studio window when the client test positions its camera."""
from pathlib import Path
import time,subprocess,re
root=Path(__file__).resolve().parents[2]
output=root/'documentations/weather-polish-20260917/views'
output.mkdir(exist_ok=True)
log=max(Path.home().joinpath('Library/Logs/Roblox').glob('*Studio*.log'),key=lambda p:p.stat().st_mtime)
seen=set()
with log.open(errors='replace') as stream:
 stream.seek(0,2)
 deadline=time.monotonic()+400
 while time.monotonic()<deadline:
  line=stream.readline()
  if not line:
   time.sleep(.15);continue
  if '[FLog::CreatorOutput] AK_POLISH_CAPTURE ' in line:
   event=line.strip().split('AK_POLISH_CAPTURE ')[-1]
   if not re.fullmatch(r'[A-Za-z]+',event) or event in seen: continue
   subprocess.run(["osascript", "-e", 'tell application "RobloxStudio" to activate'],check=True,stdout=subprocess.DEVNULL)
   time.sleep(1.1)
   subprocess.run(['screencapture','-x','-l','14955',str(output/(event+'.png'))],check=True)
   print('Captured '+event,flush=True);seen.add(event)
  if '[FLog::CreatorOutput] AK_POLISH_DONE ' in line:
   print(line.strip(),flush=True);break
print(f'Captured {len(seen)} events',flush=True)
