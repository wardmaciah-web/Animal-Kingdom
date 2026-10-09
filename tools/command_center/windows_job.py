"""Own only worker children; Windows closes the entire job if the worker crashes."""
import ctypes
from ctypes import wintypes
import os


def protect_token(data, decrypt=False):
    """Current-user DPAPI; no service account, machine grant or plaintext file."""
    if os.name != 'nt':
        raise OSError('Dashboard credential storage requires Windows DPAPI')
    class Blob(ctypes.Structure):
        _fields_ = [('size', wintypes.DWORD), ('data', ctypes.POINTER(ctypes.c_ubyte))]
    buffer = (ctypes.c_ubyte * len(data)).from_buffer_copy(data)
    source = Blob(len(data), buffer)
    result = Blob()
    library = ctypes.WinDLL('crypt32', use_last_error=True)
    method = library.CryptUnprotectData if decrypt else library.CryptProtectData
    method.argtypes = [ctypes.POINTER(Blob), ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p, wintypes.DWORD, ctypes.POINTER(Blob)]
    method.restype = wintypes.BOOL
    if not method(ctypes.byref(source), None, None, None, None, 1, ctypes.byref(result)):
        raise OSError('Windows could not access the current-user dashboard credential')
    kernel = ctypes.WinDLL('kernel32', use_last_error=True)
    kernel.LocalFree.argtypes = [ctypes.c_void_p]
    kernel.LocalFree.restype = ctypes.c_void_p
    try:
        return ctypes.string_at(result.data, result.size)
    finally:
        kernel.LocalFree(result.data)


class Job:
    def __init__(self):
        self.handle = None
        if os.name != 'nt':
            return
        class Basic(ctypes.Structure):
            _fields_ = [('ProcessTime', ctypes.c_int64), ('JobTime', ctypes.c_int64), ('Flags', wintypes.DWORD), ('MinWorkingSet', ctypes.c_size_t), ('MaxWorkingSet', ctypes.c_size_t), ('ActiveProcesses', wintypes.DWORD), ('Affinity', ctypes.c_size_t), ('Priority', wintypes.DWORD), ('Scheduling', wintypes.DWORD)]
        class IO(ctypes.Structure):
            _fields_ = [(name, ctypes.c_uint64) for name in ('ReadOps', 'WriteOps', 'OtherOps', 'ReadBytes', 'WriteBytes', 'OtherBytes')]
        class Extended(ctypes.Structure):
            _fields_ = [('Basic', Basic), ('IO', IO), ('ProcessMemory', ctypes.c_size_t), ('JobMemory', ctypes.c_size_t), ('PeakProcessMemory', ctypes.c_size_t), ('PeakJobMemory', ctypes.c_size_t)]
        self.kernel = ctypes.WinDLL('kernel32', use_last_error=True)
        self.kernel.CreateJobObjectW.argtypes = [ctypes.c_void_p, wintypes.LPCWSTR]
        self.kernel.CreateJobObjectW.restype = wintypes.HANDLE
        self.kernel.SetInformationJobObject.argtypes = [wintypes.HANDLE, ctypes.c_int, ctypes.c_void_p, wintypes.DWORD]
        self.kernel.AssignProcessToJobObject.argtypes = [wintypes.HANDLE, wintypes.HANDLE]
        self.kernel.CloseHandle.argtypes = [wintypes.HANDLE]
        self.handle = self.kernel.CreateJobObjectW(None, None)
        info = Extended()
        info.Basic.Flags = 0x2000  # JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
        if not self.handle or not self.kernel.SetInformationJobObject(self.handle, 9, ctypes.byref(info), ctypes.sizeof(info)):
            self.close()
            raise OSError('Could not establish child-process containment')

    def assign_and_resume(self, process):
        if self.handle:
            if not self.kernel.AssignProcessToJobObject(self.handle, int(process._handle)):
                process.kill()
                raise OSError('Could not contain suspended child process')
            # Resume the suspended primary thread using documented Toolhelp APIs.
            class ThreadEntry(ctypes.Structure):
                _fields_ = [('size', wintypes.DWORD), ('usage', wintypes.DWORD), ('thread', wintypes.DWORD), ('owner', wintypes.DWORD), ('base', wintypes.LONG), ('delta', wintypes.LONG), ('flags', wintypes.DWORD)]
            self.kernel.CreateToolhelp32Snapshot.argtypes = [wintypes.DWORD, wintypes.DWORD]
            self.kernel.CreateToolhelp32Snapshot.restype = wintypes.HANDLE
            self.kernel.Thread32First.argtypes = [wintypes.HANDLE, ctypes.POINTER(ThreadEntry)]
            self.kernel.Thread32Next.argtypes = [wintypes.HANDLE, ctypes.POINTER(ThreadEntry)]
            self.kernel.OpenThread.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD]
            self.kernel.OpenThread.restype = wintypes.HANDLE
            self.kernel.ResumeThread.argtypes = [wintypes.HANDLE]
            self.kernel.ResumeThread.restype = wintypes.DWORD
            snapshot = self.kernel.CreateToolhelp32Snapshot(4, 0)
            if snapshot == ctypes.c_void_p(-1).value:
                raise OSError('Cannot enumerate suspended child thread')
            entry = ThreadEntry()
            entry.size = ctypes.sizeof(entry)
            resumed = False
            try:
                found = self.kernel.Thread32First(snapshot, ctypes.byref(entry))
                while found:
                    if entry.owner == process.pid:
                        thread = self.kernel.OpenThread(2, False, entry.thread)
                        if thread:
                            try:
                                resumed = self.kernel.ResumeThread(thread) != 0xFFFFFFFF
                            finally:
                                self.kernel.CloseHandle(thread)
                        break
                    found = self.kernel.Thread32Next(snapshot, ctypes.byref(entry))
            finally:
                self.kernel.CloseHandle(snapshot)
            if not resumed:
                raise OSError('Cannot resume contained child')

    def close(self):
        if self.handle:
            self.kernel.CloseHandle(self.handle)
            self.handle = None
