

LINE_DELIMITER = '\n'
KV_DELEMITERS = [':', '=']


class TextLearner:
    def __init__(self, text: str) -> None:
        self.text = text

class TextPatternLearner(TextLearner):
    def __init__(self, text: str) -> None:
        super().__init__(text)
        self.pat_count = 0
        self.match_number = 0
        self.pats_repetition = []
        self.single_lines = []
        self.rep_lines = []

    def learn(self):
        dc = {}
        j = 0
        for i, line in enumerate(self.text.splitlines()):
            number, res = self.delim(line, KV_DELEMITERS)
            if number == 2:
                key, value = res
                if key in dc:
                    self.match_number += 1
            else:
                similarity = self.similar(i, j)



