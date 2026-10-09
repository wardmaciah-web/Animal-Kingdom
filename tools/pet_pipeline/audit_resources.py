"""Read-only Windows resource audit; does not resize pagefiles or close apps."""
import argparse
import datetime as dt
import json
from pathlib import Path
import subprocess

from pet_pipeline import preflight, check_hardware, write


def audit(root):
    report = {'time_utc':dt.datetime.now(dt.timezone.utc).isoformat(),
              'thresholds':{'ram_gib':4, 'commit_gib':16, 'vram_gib':7, 'disk_gib':10}}
    try:
        report['hardware'] = preflight(root)
        check_hardware(report['hardware'])
        if report['hardware']['free_disk_bytes'] < 10*1024**3:
            raise RuntimeError('Less than 10 GiB free storage')
        report['admission'] = 'passed'
    except Exception as error:
        report.update(admission='blocked', reason=str(error))
    command = r'''
$ErrorActionPreference='Stop'
[ordered]@{
  automatic_pagefile=(Get-CimInstance Win32_ComputerSystem).AutomaticManagedPagefile
  pagefiles=@(Get-CimInstance Win32_PageFileUsage | Select-Object Name,AllocatedBaseSize,CurrentUsage,PeakUsage)
  pagefile_settings=@(Get-CimInstance Win32_PageFileSetting | Select-Object Name,InitialSize,MaximumSize)
  disks=@(Get-Volume -DriveLetter C,D | Select-Object DriveLetter,SizeRemaining,Size)
  largest_private_processes=@(Get-Process | Sort-Object PrivateMemorySize64 -Descending | Select-Object -First 15 Id,ProcessName,WorkingSet64,PrivateMemorySize64)
  workers=@(Get-CimInstance Win32_Process | Where-Object {$_.Name -match 'python|blender|RobloxStudio'} | Select-Object ProcessId,ParentProcessId,Name)
} | ConvertTo-Json -Depth 5
'''
    result = subprocess.run(['powershell','-NoProfile','-Command',command], capture_output=True, text=True, timeout=30)
    if result.returncode: report['system_probe_error'] = result.stderr
    else: report['system'] = json.loads(result.stdout)
    return report


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True)
    args=parser.parse_args()
    report=audit(Path('D:/AnimalKingdom3D'))
    path=Path(args.output); path.parent.mkdir(parents=True,exist_ok=True); write(path, report)
    print(json.dumps(report, indent=2))
