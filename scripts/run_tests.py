"""Run production Luau rules and ProfileStore against an injected DataStore adapter.
This is not a Roblox Studio emulator. Source is compiled, not translated to Python.
"""
import os, pathlib, subprocess, tempfile
root = pathlib.Path(__file__).resolve().parents[1]
binary = os.environ.get('LUAU_BIN', 'luau')
source = (root/'src/server/ProfileStore.lua').read_text()
tests = (root/'tests/spec.luau').read_text()
generated = root/'tests/_generated.luau'
try:
    generated.write_text('local function loadProfileStore(game, script, task, warn, require)\n'+source+'\nend\n'+tests)
    subprocess.run([binary,str(generated)],cwd=root,check=True)
finally:
    generated.unlink(missing_ok=True)
