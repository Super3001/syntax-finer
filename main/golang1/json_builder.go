/*
Json 输入要求
1. key中不含有 " 和 \
*/

package main

import (
	"strings"
)

type JsonConfig struct {
	tabSpace int
}

func GetJsonConfig(tabSpace int) JsonConfig {
	return JsonConfig{tabSpace}
}

const (
	DefaultTabSpace = 4
)

func GetDefaultJsonConfig() JsonConfig {
	return GetJsonConfig(DefaultTabSpace)
}

// type JsonBuilderState int

// const (
// 	InitialState JsonBuilderState = iota,
// 	ObjectState,
// 	ListState
// )

type JsonBuilder struct {
	config JsonConfig
	json   string
	tabs   int
	//state  JsonBuilderState
}

func GetJsonBuilder(config JsonConfig) *JsonBuilder {
	return &JsonBuilder{
		config: config,
	}
}

func GetDefaultJsonBuilder() *JsonBuilder {
	return GetJsonBuilder(GetDefaultJsonConfig())
}

func (b *JsonBuilder) ToJson() string {
	return b.json
}

func (b *JsonBuilder) pop() {
	b.json = b.json[:len(b.json)-1]
}

func (b *JsonBuilder) tabIn() {
	b.tabs += b.config.tabSpace
}

func (b *JsonBuilder) tabOut() {
	if b.tabs < 0 {
		println("error: tabs < 0")
	}
	b.tabs -= b.config.tabSpace
}

func (b *JsonBuilder) newline() {
	b.json += "\n" + strings.Repeat(" ", b.tabs)
}

func (b *JsonBuilder) addAttr(key string, value string) {
	b.newline()
	/* escape patterns */
	value = strings.ReplaceAll(value, "\\", "\\\\")
	value = strings.ReplaceAll(value, "\"", "\\\"")
	b.json += "\"" + key + "\": \"" + value + "\","
}

func (b *JsonBuilder) startObj() {
	b.newline()
	b.json += "{"
	b.tabIn()
}

func (b *JsonBuilder) startList() {
	b.newline()
	b.json += "["
	b.tabIn()
}

func (b *JsonBuilder) startObjWithName(name string) {
	b.newline()
	b.json += "\"" + name + "\": {"
	b.tabIn()
}

func (b *JsonBuilder) startListWithName(name string) {
	b.newline()
	b.json += "\"" + name + "\": ["
	b.tabIn()
}

func (b *JsonBuilder) startFile(tpe int) {
	if tpe == 0 {
		b.json += "{"
	} else {
		b.json += "["
	}
	b.tabIn()
}

func (b *JsonBuilder) endObj() {
	b.pop()
	b.tabOut()
	b.newline()
	b.json += "},"
}

func (b *JsonBuilder) endList() {
	b.pop()
	b.tabOut()
	b.newline()
	b.json += "],"
}

func (b *JsonBuilder) endFile(tpe int) {
	b.pop()
	b.tabOut()
	b.newline()
	if tpe == 0 {
		b.json += "}"
	} else {
		b.json += "{"
	}
}

func (b *JsonBuilder) BuildSyntaxParserResult(parser *SyntaxParser) {
	b.startFile(0)
	b.Header2Json(parser)
	b.Table2Json(parser)
	b.endFile(0)
}

func (b *JsonBuilder) Header2Json(p *SyntaxParser) {
	if len(p.headers) == 0 {
		return
	}
	bracketHeaders := make([]HeaderT, 0)
	dotHeaders := make([]HeaderT, 0)
	for _, header := range p.headers {
		if header.kind == BracketHeaderKind {
			bracketHeaders = append(bracketHeaders, header)
		} else {
			dotHeaders = append(dotHeaders, header)
		}
	}
	if len(bracketHeaders) > 0 {
		b.startObjWithName("bracket_headers")
		for _, header := range bracketHeaders {
			b.addAttr(header.key, header.value)
		}
		b.endObj()
	}
	if len(dotHeaders) > 0 {
		b.startObjWithName("dot_headers")
		for _, header := range dotHeaders {
			b.addAttr(header.key, header.value)
		}
		b.endObj()
	}
}

func (b *JsonBuilder) Table2Json(p *SyntaxParser) {
	b.startObjWithName("id table")
	for _, id := range p.ids {
		b.addAttr(id, p.idTable[id].String())
	}
	b.endObj()
	b.startObjWithName("s-tag table")
	for _, id := range p.ids {
		b.addAttr(id, p.sTable[id])
	}
	b.endObj()
}
