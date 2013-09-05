scriptencoding utf-8
if exists('g:loaded_multitextobj')
  finish
endif
let g:loaded_multitextobj = 1

let s:save_cpo = &cpo
set cpo&vim


let g:textobj_multitextobj_debug = get(g:, "textobj_multitextobj_debug", 0)

let g:textobj_multitextobj_textobjects_i = get(g:, "textobj_multitextobj_textobjects_i", [])
let g:textobj_multitextobj_textobjects_a = get(g:, "textobj_multitextobj_textobjects_a", [])


let g:textobj_multitextobj_textobjects_group_i
\	= get(g:, "textobj_multitextobj_textobjects_group_i", {})

let g:textobj_multitextobj_textobjects_group_a
\	= get(g:, "textobj_multitextobj_textobjects_group_a", {})

let g:textobj_multitextobj_textobjects_group_list
\	= get(g:, "textobj_multitextobj_textobjects_group_list", ["A", "B", "C", "D", "E"])


let s:textobj_dict = {
\      '-': {
\        'select-a': '',
\        'select-a-function': 'textobj#multitextobj#select_a',
\        'select-i': '',
\        'select-i-function': 'textobj#multitextobj#select_i',
\      },
\}

for s:name in g:textobj_multitextobj_textobjects_group_list
	let s:textobj_dict[s:name] = {
\		'select-a': '',
\		'select-a-function': 'textobj#multitextobj#select_a_' . s:name,
\		'select-i': '',
\		'select-i-function': "textobj#multitextobj#select_i_" . s:name,
\	}
endfor


call textobj#user#plugin('multitextobj', s:textobj_dict)


let &cpo = s:save_cpo
unlet s:save_cpo
