
# Introduction

Text-Finer works to transform plain text to structural text (in JSON format) according to a dynamic BNF grammar template.

# Inputs and Outputs

input two files: `<filename>`.syntax, `<filename>`.txt

where the .syntax file contains the user-defined BNF grammar (or pre-defined ones), and the .txt file contains the plain text.

and output one file (default at project root dir): `<filename>`.tree.json

# Usage

`python run.py *filename*.syntax *filename*.txt --interpret`

*Currently, the interpreter version (in Python) is available; the compile version in Cangjie is still under development*

# workflow

## Compile version in Cangjie

```
lex
->
parse
->
qualify (e.g. LL1 check) and link (e.g. link all the name patterns)
->
generate NFA -> lex, parse, and transform regex literals to NFA
->
match text and generate JSON dynamically

```

## Interpreter version in Python

```
read and parse each line
->
deal the imports
->
link all the symbols
->
match text and generate JSON dynamically
```

note: can traverse the NFA nodes with topology order, no need to record the visit of each node.

# Advanced features

1. Regex support

*(available in interpreter version)*

2. Allow import BNF definitions from other .syntax file

*(available in interpreter version)*

3. Transform Regex to DFA

*(under development)*

4. Check the grammar, if is BNF, LL1, etc.

*(under development)*

# Version comparison

| | Compile version in Cangjie | Interpreter version in Python |
|:--:|:--:|:--:|
|import from other .syntax files|false|true|
|NFA|true|false|
|DFA|false|false|
|JSON output|false(under development)|true|

# Examples

`input file: base.syntax`

```
LINE ::= /\S.*/

WORD ::= /\w+/

NL ::= '\n' | '\r\n'

LineBlank ::= /\s*/

LineSpace ::= LineBlank LINE

LineFull ::= LineSpace NL

File[file] ::= LineFull* LineBlank

```

`python run.py demo/base.syntax demo/base.syntax --interpret`

**output:**

`output file: base.tree.json`

```
{
    "File": {
        "LineFull": [
            {
                "LineSpace": {
                    "LineBlank": "\n",
                    "LINE": "LINE ::= /\\S.*/"
                },
                "NL": "\n"
            },
            {
                "LineSpace": {
                    "LineBlank": "\n",
                    "LINE": "WORD ::= /\\w+/"
                },
                "NL": "\n"
            },
            {
                "LineSpace": {
                    "LineBlank": "\n",
                    "LINE": "NL ::= '\\n' | '\\r\\n'"
                },
                "NL": "\n"
            },
            {
                "LineSpace": {
                    "LineBlank": "\n",
                    "LINE": "LineBlank ::= /\\s*/"
                },
                "NL": "\n"
            },
            {
                "LineSpace": {
                    "LineBlank": "\n",
                    "LINE": "LineSpace ::= LineBlank LINE"
                },
                "NL": "\n"
            },
            {
                "LineSpace": {
                    "LineBlank": "\n",
                    "LINE": "LineFull ::= LineSpace NL"
                },
                "NL": "\n"
            },
            {
                "LineSpace": {
                    "LineBlank": "\n",
                    "LINE": "File[file] ::= LineFull* LineBlank"
                },
                "NL": "\n"
            }
        ],
        "LineBlank": ""
    }
}
```

