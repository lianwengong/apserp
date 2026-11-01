# -*- coding: utf-8 -*-
"""把 SQL 脚本中的 GO 批次分隔符转换成分号分隔（给不支持 GO 的 Flyway 旧版本用）。

用法：python tools/strip_go.py src/main/resources/db/migration V21__demo.sql
"""
import io
import re
import sys


def convert(text: str) -> str:
    batches = re.split(r"(?im)^\s*GO\s*$", text)
    out = []
    for b in batches:
        b = b.strip()
        if not b:
            continue
        if not b.endswith(";"):
            b += ";"
        out.append(b)
    return "\n".join(out)


if __name__ == "__main__":
    path = sys.argv[1]
    text = io.open(path, encoding="utf-8").read()
    io.open(path, "w", encoding="utf-8").write(convert(text))
    print("converted", path)
