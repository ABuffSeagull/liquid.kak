# Detection
# ‾‾‾‾‾‾‾‾‾

hook global BufCreate .*[.](liquid) %{
    set-option buffer filetype liquid
}

# Initialization
# ‾‾‾‾‾‾‾‾‾‾‾‾‾‾

hook global WinSetOption filetype=liquid %{
    require-module liquid

    hook window ModeChange pop:insert:.* -group liquid-trim-indent  liquid-trim-indent
    hook window InsertChar .* -group liquid-indent liquid-indent-on-char
    hook window InsertChar \n -group liquid-indent liquid-indent-on-new-line

    hook -once -always window WinSetOption filetype=.* %{ remove-hooks window liquid-.+ }
}

hook -group liquid-highlight global WinSetOption filetype=liquid %{
    add-highlighter window/liquid-file ref liquid-file
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/liquid-file }
}

provide-module liquid %§
require-module html
require-module json
require-module javascript

# Highlighters
# ‾‾‾‾‾‾‾‾‾‾‾‾

add-highlighter shared/liquid regions
add-highlighter shared/liquid/code  default-region group
add-highlighter shared/liquid/double_string region '"'    (?<!\\)(\\\\)*" group
add-highlighter shared/liquid/single_string region "'"    (?<!\\)(\\\\)*' fill string

add-highlighter shared/liquid/code/ regex \b(false|true)\b 0:value
add-highlighter shared/liquid/code/ regex "(\b|-)[0-9]*\.?[0-9]+\b" 0:value

add-highlighter shared/liquid/code/ regex \b(or|and|contains|for|in|if|elsif|else|endif|case|endcase|when|unless|endunless|for|break|continue|cycle|tablerow|endfor|echo|include|form|endform|liquid|paginate|endpaginate|raw|render|section|style|endstyle|javascript|endjavascript|stylesheet|endstylesheet|schema|endschema|assign|capture|increment|decrement|comment|endcomment)\b 0:keyword
add-highlighter shared/liquid/code/ regex \b\w+: 0:keyword

# Highlighter for html with liquid tags in it, i.e. the structure of conventional liquid files
add-highlighter shared/liquid-file regions
add-highlighter shared/liquid-file/html default-region ref html
add-highlighter shared/liquid-file/json           region \{%-?\h+schema\h+-?%\}             \{%-?\h+endschema\h+-?%\}               ref json
add-highlighter shared/liquid-file/javascript     region \{%-?\h+javascript\h+-?%\}         \{%-?\h+endjavascript\h+-?%\}           ref javascript
add-highlighter shared/liquid-file/css            region \{%-?\h+(style|stylesheet)\h+-?%\} \{%-?\h+endstyle|endstylesheet)\h+-?%\} ref css
add-highlighter shared/liquid-file/liquid         region \{\{                               \}\}                                    ref liquid
add-highlighter shared/liquid-file/liquid-tag     region \{%-?                              -?%\}                                   ref liquid

# Commands
# ‾‾‾‾‾‾‾‾

define-command -hidden liquid-trim-indent %{
    # remove trailing white spaces
    try %{ execute-keys -draft -itersel <a-x> s \h+$ <ret> d }
}

define-command -hidden liquid-indent-on-char %<
    evaluate-commands -draft -itersel %<
        # align closer token to its opener when alone on a line
        try %/ execute-keys -draft <a-h> <a-k> ^\h+[\]}]$ <ret> m s \A|.\z <ret> 1<a-&> /
    >
>

define-command -hidden liquid-indent-on-new-line %<
    evaluate-commands -draft -itersel %<
        # copy // comments or docblock * prefix and following white spaces
        try %{ execute-keys -draft s [^/] <ret> k <a-x> s ^\h*\K(?://|[*][^/])\h* <ret> y gh j P }
        # preserve previous line indent
        try %{ execute-keys -draft <semicolon> K <a-&> }
        # filter previous line
        try %{ execute-keys -draft k : liquid-trim-indent <ret> }
        # indent after lines beginning / ending with opener token
        try %_ execute-keys -draft k <a-x> <a-k> ^\h*[[{]|[[{]$ <ret> j <a-gt> _
        # append " * " on lines starting a multiline /** or /* comment
    	try %{ execute-keys -draft k <a-x> s ^\h*/[*][* ]? <ret> j gi i <space>*<space> }
    	# deindent closer token(s) when after cursor
    	try %_ execute-keys -draft <a-x> <a-k> ^\h*[})] <ret> gh / [})] <ret> m <a-S> 1<a-&> _
    >
>

§
