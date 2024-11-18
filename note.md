
## syntax file import
```
import支持：
dot_separator: demo.base
wildcard pattern: demo.* | *.base (with no recursive import)
special symbols: . => .syntax | [] => .*.syntax (with no recursive import)
TODO: comma composition: demo.base, demo.items
```

where to find .syntax file?
```
I.  SYNTAX_PATH = r"E:\BaiduSyncdisk\modeling\syntax"
II. IMPORT_PATH = [sys.path[0], SYNTAX_PATH]
    IMPORT_PATH_RECUR = [SYNTAX_PATH]
```

## escape pattern policy
```
1. in SimplePattern
    ' -> \'
    \ -> \\
2. in RegExpPattern
    / -> \/
    ...

```

## 目标

1. 输入.syntax和text file，输出text file于syntax对应的json

2. 类似地，处理syntax_spec file
