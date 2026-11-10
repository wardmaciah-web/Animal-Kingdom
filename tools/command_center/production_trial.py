"""Reviewable trial boundary; intentionally no host fallback or unverified VM launch.

WindowsSandbox.exe is not installed on the inspected PC. Its GUI process alone
also does not establish an owned, cancellable VM lease. A generated .wsb file is
not evidence that GPU, credential, network and shutdown isolation passed.
"""
from pathlib import Path
import xml.etree.ElementTree as ET
try:
    from .production import Denied, policy, regular_path, read_grant
except ImportError:
    from production import Denied, policy, regular_path, read_grant


def execution_readiness():
    return {
        'ready': False,
        'windows_sandbox_installed': Path('C:/Windows/System32/WindowsSandbox.exe').is_file(),
        'reason': 'No verified GPU execution backend with credential/network isolation and an owned cancellable VM lease. Host execution is prohibited.',
        'required_evidence': ['credential access denied','network denied','unmapped host paths denied','approved assets read/write denied','only owned VM cancelled on watchdog/stop/crash','CUDA usable within isolated VM','single Coati seed and artifact limits enforced'],
    }


def plan_offline_sandbox():
    """Generate a review artifact only. Never call WindowsSandbox or PowerShell."""
    p = policy()
    bundle = regular_path(Path(p['scratch_root']), 'reviewed-bundle')
    # No caller-selected mount paths: both roots are fixed policy capabilities.
    output = regular_path(Path(p['output_root']), 'trial-1')
    root = ET.Element('Configuration')
    for key, value in [('Networking','Disable'),('ClipboardRedirection','Disable'),('AudioInput','Disable'),('VideoInput','Disable'),('PrinterRedirection','Disable'),('ProtectedClient','Enable'),('vGPU','Enable'),('MemoryInMB','8192')]:
        ET.SubElement(root,key).text = value
    mappings = ET.SubElement(root,'MappedFolders')
    for host, guest, readonly in [(bundle,'C:\\AK\\bundle','true'),(output,'C:\\AK\\output','false')]:
        mapping = ET.SubElement(mappings,'MappedFolder')
        ET.SubElement(mapping,'HostFolder').text = str(host)
        ET.SubElement(mapping,'SandboxFolder').text = guest
        ET.SubElement(mapping,'ReadOnly').text = readonly
    # No logon command: this is a policy artifact, not an executable dispatch.
    return ET.tostring(root,encoding='unicode')


def request_trial(runtime, action, arguments):
    read_grant(runtime)
    if action != 'coati-concept-once' or arguments != {}:
        raise Denied('Only the exact reviewed trial action with no remote arguments exists')
    raise Denied(execution_readiness()['reason'])
