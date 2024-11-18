// 语法说明

PYERR ::
	'Traceback ' LINE NL (BLANK LINE NL)* LINE NL
	;

ESERR1 ::
	'es exception ' LINE NL ('es exception' LINE NL)*
	;
	
ESERR ::
	ES_OPERATION ' es exception, ' LINE NL
	;
	
ES_ACTION ::
	'es_write' | 'es_search' | 'es_delete' | 'es_check_index_exist' | 'es_create_data_stream'
	;

LINE ::= /\S[^\n]*/
NL ::= /\n/
