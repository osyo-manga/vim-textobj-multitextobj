## vim-textobj-multitextobj

複数の textobj を1つにまとめる textobj です。


#### Example

```vim
" 上から順に textobj を適用していき、該当するものが使用される
let g:textobj_multitextobj_textobjects_i = [
\	"\<Plug>(textobj-url-i)",
\	"\<Plug>(textobj-multiblock-i)",
\	"\<Plug>(textobj-function-i)",
\	"\<Plug>(textobj-entire-i)",
\]

omap amt <Plug>(textobj-multitextobj-a)
omap imt <Plug>(textobj-multitextobj-i)
vmap amt <Plug>(textobj-multitextobj-a)
vmap imt <Plug>(textobj-multitextobj-i)
```




