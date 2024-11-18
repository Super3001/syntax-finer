
import json
import re

from collections import UserList
from reader import TextReaderTree

FILEPATH = "D:\\data-platform\\process\\ruixing.out"

# status
NOERROR = 0
PYERROR_TRACEBACK = 1
ESERROR = 2

# shortnames
EX_AGENT = "agent_key_logs"
EX_NETWORK = "network_key_logs"
EX_LOC = "loc_key_logs"

class NoQuotesPrintedList(UserList):
    def __str__(self) -> str:
        return "[" + ", ".join(self) + "]"

# basic patterns
pat_filepath = '[^\\:\\*\\?"<>\\|\n\t]+'
pat_project = '.+_.+_.+' # 必要但不充分
pat_datestr = '[0-9]{4}-[0-9]{2}-[0-9]{2}'
pat_indic = 'odom|error|sys_error|ci|fsize|disk|miss|init_pose|cam_error|charging|docking|docking_dev|navigation|block|marker|dyob_failed|version|time_deviation|network|robot_task|erms_job|labor|health|map_info|battery|probability|power_lift'

def short_traceback(traceback: str):
    lines = traceback.split('\n')
    return lines[1].strip()

def short_esError(errmsg: str):
    idx = errmsg.find("caused by")
    return errmsg[:idx]
    # if "ConnectTimeoutError" in errmsg:
    #     return "Connect Timeout Error"
    # else:
    #     return "Connection Error"

def script_name_from_traceback(traceback: str):
    return re.search('(\\w+)\\.py', short_traceback(traceback)).group(1)

class LogReaderLinear:
    def __init__(self, filepath) -> None:
        self.filepath = filepath
        self.wrb_msg = "**【数据处理】**|<font color=\"red\">[error]</font>"
        self.error_dict = ""
        self.project = ""
        self.date_str = ""

    def parse(self):
        error_dict = {
            "python_error": [],
            "es_error": []
        }
        stashed_lines = []
        with open(self.filepath, 'r', encoding='utf-8') as f:
            content = f.readlines()
        
        errmsg = None
        traceback = None
        state = NOERROR
        for i, line in enumerate(content):
            if state == NOERROR:
                if line.startswith("Traceback"):
                    state = PYERROR_TRACEBACK
                    traceback = line
                elif line.startswith("+ project="):
                    project = line.replace("+ project=", '').strip()
                    if project != self.project:
                        self.wrb_msg += f"|项目：{project}"
                        self.project = project
                elif line.startswith("+ date_str="):
                    date_str = line.replace("+ date_str=", '').strip()
                    if self.date_str != date_str:
                        self.wrb_msg += f"|日期：{date_str}"
                        self.date_str = date_str
                elif line.startswith('es exception'):
                    new_es_exception = [line]
                    error_dict["es_error"].append(new_es_exception)
                    state = ESERROR
            elif state == PYERROR_TRACEBACK:
                if line[0] in [' ', '\t']:
                    traceback += line
                else:
                    errmsg = line.strip()
                    traceback = traceback.strip()
                    state = NOERROR
                    self.wrb_msg += f"|>{short_traceback(traceback)}|>{errmsg}|"
                    error_dict["python_error"].append({
                        "project": project,
                        "date": date_str,
                        "trackback": traceback,
                        "errmsg": errmsg
                    })
            elif state == ESERROR:
                if line.startswith('es exception'):
                    error_dict["es_error"][-1].append(line)
                else:
                    state = NOERROR
                    stashed_lines.append([i, line])
                
        self.error_dict = error_dict
        self.stashed_lines = stashed_lines
    
    def output(self):
        print(json.dumps({"error_dict": self.error_dict, "stashed_lines": self.stashed_lines}, indent=4))

    

pat_esError1_line1 = re.compile(f'es exception, (\\w+) is ({pat_datestr}) project is ({pat_project})')
pat_esError1_line2 = re.compile(f'es exception, (\\w+) : (.*)')
pat_esError = re.compile(f'\\w+ es exception, .*')

class LogReaderLL1:
    def __init__(self, filepath) -> None:
        self.filepath = filepath
        self.wrb_msg = "**【数据统计分析】**|<font color=\"red\">[error]</font>"
        self.wrb_table_msg = "**【数据统计分析】**|<font color=\"red\">[error]</font>|\
\\| 项目 \\| 日期 \\| 分析指标 \\| Failed \\|\
|\\| - \\| - \\| - \\| - \\|"
        self.error_dict = None
        self.error_count = 0
        self.cur: int = -1

    def peek(self) -> str:
        return self.lines[self.cur] if not self.eof() else ''

    def consume(self) -> str:
        if not self.eof():
            line = self.lines[self.cur]
            self.cur += 1
            return line
        else:
            return ''
    
    def eof(self):
        return self.cur >= self.length

    def parse(self):
        error_dict = {
            "python_error": [],
            "es_error": []
        }
        with open(self.filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        self.lines: list[str] = lines
        self.cur = 0
        self.length = len(self.lines)
        
        errmsg = None
        traceback = None
        while not self.eof():
            line = self.consume()
            if line.startswith("Traceback"):
                traceback = line
                while self.peek()[0] in [' ', '\t']:
                    traceback += self.consume()
                errmsg = self.consume().strip()
                traceback = traceback.strip()
                self.wrb_msg += f"|>项目: {project} 日期: {date_str} 分析指标: {script_name_from_traceback(traceback)}|>Failed: {short_traceback(traceback)}|>{errmsg}|"
                self.wrb_table_msg += f"|\\|{project}\\|{date_str}\\|{short_traceback(traceback)}; {errmsg}\\|"
                error_dict["python_error"].append({
                    "project": project,
                    "date": date_str,
                    "trackback": traceback,
                    "errmsg": errmsg
                })
                self.error_count += 1
            elif line.startswith("+ project="):
                project = line.replace("+ project=", '').strip()
            elif line.startswith("+ date_str="):
                date_str = line.replace("+ date_str=", '').strip()
            elif line.startswith('es exception'):
                new_es_exception = [line]
                while self.peek().startswith('es exception'):
                    new_es_exception.append(self.consume())
                es_exception = {}
                for e_line in new_es_exception:
                    if re.match(pat_esError1_line1, e_line):
                        matchObj = re.match(pat_esError1_line1, e_line)
                        es_exception["indic"] = matchObj.group(1)
                        es_exception['date'] = matchObj.group(2)
                        es_exception['project'] = matchObj.group(3)
                    elif re.match(pat_esError1_line2, e_line):
                        matchObj = re.match(pat_esError1_line2, e_line)
                        es_exception['error'] = matchObj.group()
                        indic = matchObj.group(1)
                        assert indic == es_exception["indic"]
                self.wrb_msg += f"|>项目: {project} 日期: {date_str} 分析指标: {es_exception['indic']}|>Failed: {short_esError(es_exception['error'])}|"
                self.wrb_table_msg += f"|\\|{project}\\|{date_str}\\|{es_exception['indic']}|{short_esError(es_exception['error'])}\\|"
                error_dict["es_error"].append(es_exception)
                self.error_count += 1
            elif re.match(pat_esError, line):
                error_dict["es_error"].append({
                    "date": date_str,
                    "project": project,
                    "error": line.strip()
                })
                self.wrb_msg += f"|>项目: {project} 日期: {date_str} 分析指标: (EsAction)|>Failed: {short_esError(line)}|"
                self.wrb_table_msg += f"|\\|{project}\\|{date_str}\\|\\|{short_esError(line)}\\|"
                self.error_count += 1

        self.error_dict = error_dict
    
    def output(self):
        print(json.dumps(self.error_dict, indent=4))

        
'''
pat_PyError = re.compile('(Trackback .*\\n)( .*\\n|\\t.*\\n)*(.*\\n)')
pat_EsError1 = re.compile('es exception (.*\n)(es exception .*\n)*')

class LogReaderRE:
    def __init__(self, filepath) -> None:
        self.filepath = filepath
        self.wrb_msg = "**【数据处理】**|<font color=\"red\">[error]</font>"
        self.error_dict = None

    def parse(self):
        error_dict = {
            "python_error": [],
            "es_error": []
        }
        with open(self.filepath, 'r', encoding='utf-8') as f:
            text = f.read()
        self.text = text

        for pyerror in re.findall(pat_PyError, text):
            matchObj = re.match(pat_PyError, pyerror)
            pyerrorObj = {
                "trackback": matchObj.group(0) + matchObj.group(1),
                "errmsg": matchObj.group(2)
            }
            error_dict["python_error"].append(pyerrorObj)

        self.error_dict = error_dict

    def output(self):
        print(json.dumps(self.error_dict, indent=4))
'''   

pat_process_header = re.compile('\\+ path={path}\\n\\+ project={project}\\n\\+ date_str={date_str}\\n'.format(
        path=pat_filepath, project=pat_project, date_str=pat_datestr
    ))

pat_process_metadata = re.compile('\\w+=\\S*\\n')
esc_pat_process_metadata = re.compile('\\+ ')

pat_part1_header = re.compile(f"unpack {pat_filepath}")
pat_part2_header = re.compile("\\+ echo 'stats indic \\.\\.\\.'")
pat_part3_header = re.compile("\\+ echo 'extract indic \\.\\.\\.'")

pat_warehouse = re.compile(f'warehouse:{pat_project}\\n')
pat_part1_transmmision_error = re.compile('[0-9]{4}-[0-9]{2}-[0-9]{2}.tar.gz Error is not recoverable')
pat_part1_fileNotExist_error = re.compile('[0-9]{4}-[0-9]{2}-[0-9]{2}.tar.gz Error is not recoverable')

pat_part3_metadata_ender = re.compile('indic:\\w+\\n')
pat_indicator = "indicator: (\\w+)"
part3_sublist = ["extract_agent_key_logs",
                "extract_network_key_logs",
                "extract_loc_key_logs",
                "get_pose_info",
                "get_person_info"]

class LogReaderTree(TextReaderTree):
    def __init__(self, filepath):
        super().__init__(filepath)
        
    def clean(self, text):
        return text.replace('\u0000', '')

    def parse(self, text="", scope="file"):
        if scope == "file":
            tree = self.part_by_given_name(pat_process_header, self.text)
            for i, each in enumerate(tree["main_body"]):
                tree["main_body"][i] = self.parse(each, scope="process_with_header")

            self.tree = tree
        elif scope == "process_with_header":
            pwh = self.split_metadata(pat_process_metadata, text, esc_pat=esc_pat_process_metadata)
            pwh["metadata"] = self.extract_param("=", pwh["metadata"])
            pwh["content"] = self.parse(pwh["content"], "process")
            return pwh
        elif scope == "process":
            process = self.take_by_given_name(pat_part2_header, text, "part1", "rest", mode="merge_after")
            process["part1"] = self.parse(process["part1"], "part1")
            part1_rest = self.parse(process["rest"], "part1_rest")
            process["part2"] = part1_rest["part2"]
            process["part3"] = part1_rest["part3"]
            del process["rest"]
            return process
        elif scope == "part1":
            part1 = self.take_by_given_name(pat_warehouse, text, body_name="warehouse", tail_name="log_or_error", mode="escape")
            part1["warehouse"] = part1["warehouse"].replace("warehouse:", '').strip()
            '''nonsense
            # def __(v: str): v.replace("warehouse:", '').strip()
            # part1["warehouse"] = self.deal_direct(part1["warehouse"], __)
            # I really do not want this, but in PEP-3107/#lambda, says "lambda's syntax does not support annotations. The syntax oflambda could be changed to support annotations, by requiring parentheses around the parameter list. However it was decided  not to make this change because: It would be an incompatible change. Lambda's are neutered anyway. The lambda can always be changed to a function." <-- to type an argument in a lambda expression is painstaking, maybe the language feature is defective :('''
            part1_log_or_error = self.parse(part1["log_or_error"], "part1_log_or_error")
            if "log" in part1_log_or_error:
                part1["log"] = part1_log_or_error["log"]
            if "error" in part1_log_or_error:
                part1["error"] = part1_log_or_error["error"]
            del part1["log_or_error"]
            return part1
        elif scope == "part1_log_or_error":
            part1_transmmision_error = self.take_by_given_name(pat_part1_transmmision_error, text, mode="only")
            if part1_transmmision_error["body"]:
                return {"error": {"type": "Transmmission Error", "errmeg": part1_transmmision_error}}
            part1_fileNotExist_error = self.take_by_given_name(pat_part1_fileNotExist_error, text, mode="only")
            if part1_fileNotExist_error["body"]:
                return {"error": {"type": "FileNotExist Error", "errmeg": part1_fileNotExist_error}}
            return {"log": text}
            # files = []
            # for line in text.splitlines():
            #     files.append(line)
            # return {"log": {"extracted_files": files}}
        elif scope == "part1_rest":
            part1_rest = self.take_by_given_name(pat_part3_header, text, "part2", "part3", mode="merge_after")
            part1_rest["part2"] = self.parse(part1_rest["part2"], "part2")
            part1_rest["part3"] = self.parse(part1_rest["part3"], "part3")
            return part1_rest
        elif scope == "part2":
            return text
        elif scope == "part3":
            # part3 = self.take_by_given_name(pat_part3_metadata_ender, text, body_name="metadata", tail_name="body", mode="merge_before")
            part3 = self.part_by_given_name(pat_indicator, text, pre_name="metadata", body_name="body")
            if part3["metadata"]:
                part3_metadata = part3["metadata"]
                part3["metadata"] = {"headers": []}
                for line in part3_metadata.splitlines():
                    if not line.startswith("+ ") and ":" in line:
                        key, value = line.split(":")
                        part3["metadata"][key] = value
                    else:
                        part3["metadata"]["headers"].append(line)
            for i in range(len(part3["body"])):
                indicator = re.search(pat_indicator, part3["body"][i]).group(1)
                part3["body"][i] = self.parse(part3["body"][i], scope=indicator)
            return part3
        elif scope in part3_sublist:
            return {"indicator": scope, "content": self.learn_from_pattern(text)}
             

if __name__ == "__main__":
    # reader = LogReaderLinear(FILEPATH)
    reader = LogReaderLL1(FILEPATH)
    # reader = LogReaderTree(FILEPATH)
    reader.parse()
    # reader.output()
    # reader.save_json('../')

