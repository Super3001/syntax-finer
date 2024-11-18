interface RootObject {
  LineFull: LineFull[];
  LineBlank: string;
}

interface LineFull {
  LineSpace: LineSpace;
  NL: string;
}

interface LineSpace {
  LineBlank: string;
  LINE: string;
}
