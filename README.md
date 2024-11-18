
# Introduction

Text-Finer works to transform plain text to structural text (in JSON format) according to a dynamic BNF grammar template.

# Inputs and Outputs

input two files: `<filename>`.syntax, `<filename>`.txt

where the .syntax file contains the user-defined BNF grammar (or pre-defined ones), and the .txt file contains the plain text.

and output one file (default at project root dir): `<filename>`.tree.json

# Usage

`python run.py *filename*.syntax *filename*.txt --interpret`

*Currently, the interpreter version (in Python) is available; the compile version (in Go, or Cangjie in the future) is still under development*

# Advanced features

1. Regex support

*(available in interpreter version)*

2. Allow import BNF definitions from other .syntax file

*(available in interpreter version)*

3. Transform Regex to DFA

*(under development)*

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

