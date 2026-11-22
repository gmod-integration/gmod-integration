#!/usr/bin/env python3
"""Run mocked transport regressions with Lua; this does not emulate a GMod server."""

from __future__ import annotations

import ctypes
import ctypes.util
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parent.parent
LONG_BRACKET = re.compile(r"\[(=*)\[")


def glua_operators(source: str) -> str:
    """Translate GLua operators while preserving strings and comments byte-for-byte."""
    result: list[str] = []
    position = 0
    while position < len(source):
        char = source[position]
        if char in "\"'":
            end = position + 1
            while end < len(source):
                if source[end] == "\\":
                    end += 2
                elif source[end] == char:
                    end += 1
                    break
                else:
                    end += 1
            result.append(source[position:end])
            position = end
            continue
        comment = source.startswith("--", position)
        long = LONG_BRACKET.match(source, position + 2 if comment else position)
        if long:
            start = position + (2 if comment else 0)
            closing = "]" + long.group(1) + "]"
            end = source.find(closing, start + len(long.group()))
            end = len(source) if end == -1 else end + len(closing)
            result.append(source[position:end])
            position = end
            continue
        if comment or source.startswith("//", position):
            end = source.find("\n", position)
            end = len(source) if end == -1 else end
            result.append("--" + source[position + 2 : end])
            position = end
            continue
        if source.startswith("/*", position):
            end = source.find("*/", position + 2)
            end = len(source) if end == -1 else end + 2
            content = source[position + 2 : end - 2]
            marker = "="
            while "]" + marker + "]" in content:
                marker += "="
            result.append("--[" + marker + "[" + content + "]" + marker + "]")
            position = end
            continue
        replaced = False
        for original, replacement in (("!=", "~="), ("&&", " and "), ("||", " or "), ("!", "not ")):
            if source.startswith(original, position):
                result.append(replacement)
                position += len(original)
                replaced = True
                break
        if not replaced:
            result.append(char)
            position += 1
    return "".join(result)


def lua_string(value: str) -> str:
    marker = "="
    while "]" + marker + "]" in value:
        marker += "="
    return "[" + marker + "[" + value + "]" + marker + "]"


def bundle(specification: Path) -> bytes:
    statements = ["local gluaSources = {}"]
    for path in sorted((ROOT / "lua").rglob("*.lua")):
        relative = path.relative_to(ROOT).as_posix()
        statements.append("gluaSources[ " + lua_string(relative) + " ] = " + lua_string(glua_operators(path.read_text())))
    statements.append("""
function loadGLua(path)
    local source = assert(gluaSources[path], 'Missing test source: ' .. tostring(path))
    local chunk, err = (loadstring or load)(source, '@' .. path)
    assert(chunk, err)
    return chunk()
end
""")
    statements.append(glua_operators(specification.read_text()))
    return "\n".join(statements).encode()


def run_library(code: bytes, specification: str) -> None:
    name = ctypes.util.find_library("lua5.4") or ctypes.util.find_library("lua5.3")
    if not name:
        raise RuntimeError("Install Lua 5.4/5.3 or its shared library to run mocked Lua regression tests.")
    library = ctypes.CDLL(name)
    library.luaL_newstate.restype = ctypes.c_void_p
    library.luaL_openlibs.argtypes = [ctypes.c_void_p]
    library.luaL_loadbufferx.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_size_t, ctypes.c_char_p, ctypes.c_char_p]
    library.luaL_loadbufferx.restype = ctypes.c_int
    library.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_ssize_t, ctypes.c_void_p]
    library.lua_pcallk.restype = ctypes.c_int
    library.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.POINTER(ctypes.c_size_t)]
    library.lua_tolstring.restype = ctypes.c_char_p
    library.lua_close.argtypes = [ctypes.c_void_p]
    state = library.luaL_newstate()
    if not state:
        raise RuntimeError("Unable to allocate the Lua interpreter.")
    try:
        library.luaL_openlibs(state)
        status = library.luaL_loadbufferx(state, code, len(code), specification.encode(), None)
        if status == 0:
            status = library.lua_pcallk(state, 0, 0, 0, 0, None)
        if status != 0:
            message = library.lua_tolstring(state, -1, None)
            raise RuntimeError(message.decode(errors="replace") if message else "Lua test failed.")
    finally:
        library.lua_close(state)


def main() -> int:
    paths = [ROOT / value for value in sys.argv[1:]] or sorted((ROOT / "tests").glob("*_spec.lua"))
    if not paths:
        raise RuntimeError("No Lua specifications found in tests/.")
    executable = next((found for name in ("lua5.4", "lua5.3", "lua", "luajit") if (found := shutil.which(name))), None)
    for path in paths:
        path = path.resolve()
        if not path.is_relative_to(ROOT) or not path.is_file():
            raise RuntimeError("Specification must be a file inside the addon repository.")
        relative = path.relative_to(ROOT).as_posix()
        code = bundle(path)
        if executable:
            with tempfile.NamedTemporaryFile(suffix=".lua") as temporary:
                temporary.write(code)
                temporary.flush()
                subprocess.run([executable, temporary.name], cwd=ROOT, check=True)
        else:
            run_library(code, relative)
        print("PASS " + relative, flush=True)
    print("Mocked Lua checks passed; Garry's Mod staging validation is still required.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, OSError, subprocess.CalledProcessError) as error:
        print("FAIL " + str(error), file=sys.stderr)
        raise SystemExit(1)
