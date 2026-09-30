"""Compatibility entry: use the current authored-tree regression instead of retired egg stands."""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).with_name('prepare_tree_loop_test.py')),run_name='__main__')
Path('/private/tmp/ak-phase2-command.lua').write_text(Path('/private/tmp/ak-loop-command.lua').read_text())
