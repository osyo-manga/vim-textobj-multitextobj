scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim


function! s:uniq(list)
	return reverse(filter(reverse(a:list), "count(a:list, v:val) <= 1"))
endfunction



let s:nullpos = [0, 0]

" a <= b
function! s:pos_less_equal(a, b)
	return a:a[0] == a:b[0] ? a:a[1] <= a:b[1] : a:a[0] <= a:b[0]
endfunction

" a == b
function! s:pos_equal(a, b)
	return a:a[0] == a:b[0] && a:a[1] == a:b[1]
endfunction

" a < b
function! s:pos_less(a, b)
	return a:a[0] == a:b[0] ? a:a[1] < a:b[1] : a:a[0] < a:b[0]
endfunction

" begin < pos && pos < end
function! s:is_in(range, pos)
	return type(a:pos) == type([]) && type(get(a:pos, 0)) == type([])
\		 ? len(a:pos) == len(filter(copy(a:pos), "s:is_in(a:range, v:val)"))
\		 : s:pos_less(a:range[0], a:pos) && s:pos_less(a:pos, a:range[1])
endfunction

function! s:pos_next(pos)
	if a:pos == s:nullpos
		return a:pos
	endif
	let lnum = a:pos[0]
	let col  = a:pos[1]
	let line_size = len(getline(lnum))
	return [
\		line_size == col ? lnum + 1 : lnum,
\		line_size == col ? 1        : col + 1,
\	]
endfunction

function! s:pos_prev(pos)
	if a:pos == s:nullpos
		return a:pos
	endif
	let lnum = a:pos[0]
	let col  = a:pos[1]
	let line_size = len(getline(lnum))
	return [
\		line_size == 0 ? lnum-1               : lnum,
\		line_size == 0 ? len(getline(lnum-1)) : col - 1,
\	]
endfunction


function! s:as_config(config)
	let default = {
\		"textobj" : "",
\		"is_cursor_in" : 0,
\		"noremap" : 0,
\	}
	let config
\		= type(a:config) == type("") ? { "textobj" : a:config }
\		: type(a:config) == type({}) ? a:config
\		: {}
	return extend(default, config)
endfunction


let s:region = []
let s:wise = ""
function! textobj#multitextobj#region_operator(wise)
	let reg_save = @@
	let s:wise = a:wise
	let s:region = [getpos("'[")[1:], getpos("']")[1:]]
	let @@ = reg_save
endfunction

nnoremap <silent> <Plug>(textobj-multitextobj-region-operator)
\	:<C-u>set operatorfunc=textobj#multitextobj#region_operator<CR>g@


function! textobj#multitextobj#region_from_textobj(textobj)
	let s:region = []
	let config = s:as_config(a:textobj)

	let pos = getpos(".")
	try
		silent execute (config.noremap ? 'onoremap' : 'omap') '<expr>'
\			'<Plug>(textobj-multitextobj-target)' string(config.textobj)

		let tmp = &operatorfunc
		silent execute "normal \<Plug>(textobj-multitextobj-region-operator)\<Plug>(textobj-multitextobj-target)"
		let &operatorfunc = tmp

		if !empty(s:region) && !s:pos_less_equal(s:region[0], s:region[1])
			return ["", []]
		endif
		if !empty(s:region) && config.is_cursor_in && (s:pos_less(pos[1:], s:region[0]) || s:pos_less(s:region[1], pos[1:]))
			return ["", []]
		endif
		return deepcopy([s:wise, s:region])
	finally
		call setpos(".", pos)
	endtry
endfunction


function! textobj#multitextobj#regex_from_region(first, last)
	if a:first == a:last
		return printf('\%%%dl\%%%dc', a:first[0], a:first[1])
	elseif a:first[0] == a:last[0]
		return printf('\%%%dl\%%>%dc\%%<%dc', a:first[0], a:first[1]-1, a:last[1]+1)
	elseif a:last[0] - a:first[0] == 1
		return  printf('\%%%dl\%%>%dc', a:first[0], a:first[1]-1)
\		. "\\|" . printf('\%%%dl\%%<%dc', a:last[0], a:last[1]+1)
	else
		return  printf('\%%%dl\%%>%dc', a:first[0], a:first[1]-1)
\		. "\\|" . printf('\%%>%dl\%%<%dl', a:first[0], a:last[0])
\		. "\\|" . printf('\%%%dl\%%<%dc', a:last[0], a:last[1]+1)
	endif
endfunction


function! textobj#multitextobj#highlight_from_textobj(textobj, match_group)
	match none
	let region = textobj#multitextobj#region_from_textobj(a:textobj)[1]
	if empty(region)
		return
	endif
	let regex = textobj#multitextobj#regex_from_region(region[0], region[1])
	execute printf("match %s /%s/", a:match_group, regex)
endfunction


function! s:to_cursorpos(pos)
	if a:pos == s:nullpos
		return [0, 0, 0, 0]
	endif
	return [0, a:pos[0], a:pos[1], 0]
endfunction


function! s:select_inner(textobjects)
	let regions = map(copy(a:textobjects), "textobj#multitextobj#region_from_textobj(v:val)")
	call filter(regions, "!empty(v:val[1])")
	let regions = filter(copy(regions), 'empty(filter(copy(regions), "s:is_in(".string(v:val[1]).", v:val[1])"))')
	let result = get(regions, 0, ["", []])
	if empty(result[1])
		return ["", []]
	endif
	return result
" 	return [wise == "line" ? "V" : "v", s:to_cursorpos(region[0]), s:to_cursorpos(region[1])]
endfunction


function! s:select(textobjects)
	for textobj in a:textobjects
		if type(textobj) == type([])
			let [wise, region] = s:select_inner(textobj)
		else
			let [wise, region] = textobj#multitextobj#region_from_textobj(textobj)
		endif
		if region != []
			if g:textobj_multitextobj_debug
				echom string(textobj)
			endif
			return [wise == "line" ? "V" : "v", s:to_cursorpos(region[0]), s:to_cursorpos(region[1])]
		endif
		unlet textobj
	endfor
	return 0
endfunction


function! s:textobjects(name)
	return s:uniq(get(b:, a:name, []) + get(g:, a:name, []))
endfunction


function! textobj#multitextobj#select_a()
	return s:select(s:textobjects("textobj_multitextobj_textobjects_a"))
endfunction


function! textobj#multitextobj#select_i()
	return s:select(s:textobjects("textobj_multitextobj_textobjects_i"))
endfunction


function! s:textobjects_group(dict_name, key_name)
	return s:uniq(
\		get(get(b:, a:dict_name, {}), a:key_name, [])
\	  + get(get(g:, a:dict_name, {}), a:key_name, [])
\	)
endfunction


for s:name in g:textobj_multitextobj_textobjects_group_list
	execute
\"	function! textobj#multitextobj#select_i_" . s:name . "()\n"
\"		return s:select(s:textobjects_group('textobj_multitextobj_textobjects_group_i', " . string(s:name) . "))\n"
\"	endfunction"

	execute
\"	function! textobj#multitextobj#select_a_" . s:name . "()\n"
\"		return s:select(s:textobjects_group('textobj_multitextobj_textobjects_group_a', " . string(s:name) . "))\n"
\"	endfunction"
endfor


function! textobj#multitextobj#i(group)
	
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
