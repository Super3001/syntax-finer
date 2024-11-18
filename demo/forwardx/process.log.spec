// handle.log.spec
%(PROJ, DATE, INDEX)

- (.){.watchdog[16]}echo "unpack ${path}/$FILENAME"

- (.){unpack_data_from_project.sh[27,0]}echo warehouse:$warehouse ::= 'warehouse:' PROJ NL :=> "warehouse:.*" 
	
	- (|,+){unpack_data_from_project.sh[41,8]}$date_str".tar.gz Error is not recoverable" ::= DATE '.tar.gz Error is not recoverable' NL :=> "[0-9]{4}-[0-9]{2}-[0-9]{2}.tar.gz Error is not recoverable"
		=> sig("Transmission Error"), %PROJ, %DATE
	
	- (|,+){unpack_data_from_project.sh[79,4]}$date_str".tar.gz is not exist" ::= DATE '.tar.gz is not exist' NL :=> 
		=> sig("FileNotExist Error"), %PROJ, %DATE

- (.)echo date:$date ::= 'date:' DATE :=> "date:[0-9]{4}-[0-9]{2}-[0-9]{2}"

- (.)echo indic:All ::= 'indic:All' :=> "indic:All"

-..(index <- %INDEX%) (.,>[1.subflow]($index))python3 delete_data_from_index_by_project_date.py $index $date $project ::= SUBFLOW_1* :=> ...

- (.,>[2.subflow])python3 odom_stat.py $date $project ::= SUBFLOW_2 :=> ...

// 1.subflow.log.spec
#(index)
%(PROJ, DATE, INDEX, TS)
%-> SUBFLOW_1

- (.)print("index is:", index) ::= 'index is:' INDEX
    
- (.)print("project is:", project) ::= 'project is:' PROJ
    
- (.)print("timestamp from", timestamp, "to", totimestamp) ::= 'timestamp from' TS 'to' TS

- (+)es.delete_by_query(index=index, body=doc) ::= PYES_ERRORMSG :=> ...

// agentkl.subflow.log.spec

- (.){extract_agent_key_logs.py[147]}print("date_str:",date_str)

-..(project <- %PROJECT_IN_DIR%)
	
	- (|,+){extract_agent_key_logs.py[96]}es = Elasticsearch(es_name_passward+"@"+es_host, use_ssl=True, ca_certs='es01_ca.crt') ::= PYES_ERRORMSG :=> ...
	
	- (|)
	
		- (.){extract_agent_key_logs.py[104]}print("start warehouse:", project)
		
		-..(robotid <- %ROBOT_ID%)
		
			- (.)print("start robot id:", robot_id)
			
			- (.)print("file_path:", file_path)
			
			- (+)
			
				- (.)print("len receive:", len(results))
			
				- (.)print("len finish:", len(result_finish))
			
				- (.)print("len audio:", len(audio_result))
			
				- (.)print("len results:", len(results))
			
			- (+)[131]es_write(es=es, actions=actions, date_str=date_str, project=project)
			
				- (+)[89]print("es exception, extra_agent_key_logs date is", date_str, "project is", project); print("es exception, extra_agent_key_logs :", ex)
			
		- (+)[135]es_write(es=es, actions=actions, date_str=date_str, project=project)
			
			- (+)[89]print("es exception, extra_agent_key_logs date is", date_str, "project is", project); print("es exception, extra_agent_key_logs :", ex)
			

			
			