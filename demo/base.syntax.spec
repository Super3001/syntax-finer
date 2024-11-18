
LINE[atom] ::= /\S.*/

WORD[atom] ::= /\w+/

NL[hex] ::= '\n' | '\r\n'

LineBlank[hex] ::= /\s*/

LineSpace[fold] ::
    d$LineBlank p$LINE
    ;

LineFull[fold] ::
    p$LineSpace d$NL
    ;

File[file] ::= LineFull* LineBlank
    => *(1) > "lines"
