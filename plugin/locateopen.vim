" Name:          locateopen.vim (global plugin)
" Version:       0.6.1
" Author:        Ciaran McCreesh <ciaranm at gentoo.org>
" Updates:       http://dev.gentoo.org/~ciaranm/vim/
" Purpose:       Open a file for editing without knowing the file's path
"
" License:       You may redistribute this plugin under the same terms as Vim
"                itself.
"
" Usage:         :LocateEdit somefile.txt
"                :LocateSplit somefile.txt
"
" Requirements:  Needs 'slocate' or a compatible program. You'll also need an
"                up-to-date locate database. Most systems seem to run updatedb
"                on a daily cron, so you should be okay. Note that recently
"                created files may not show up because of this.
"
" ChangeLog:
"     v0.6.1 (20031215)
"         * slocate doesn't return sensible return codes on failure, so a
"           better error check is needed
"
"     v0.6.0 (20031215)
"         * first release to the Real World

let s:slocate_app        = "slocate"
let s:slocate_args       = "-r"
let s:slocate_cmd        = s:slocate_app . " " . s:slocate_args
let s:path_seperator     = "/"

" Escape str for passing to slocate -r, so that magic characters aren't
" interpreted as regex metachars.
function! s:EscapeForLocate(str)
    " hmm, toothpick syndrome
    return substitute(a:str, "\\W", "\\\\\\0", "g")
endfun

" Find file, and if there are several then ask the user which one is
" intended.
function! s:LocateFile(file)
    let l:options = system(s:slocate_cmd . " '" . s:path_seperator .
        \ s:EscapeForLocate(a:file) . "$'")

    " Do we have an error? Please please please give me suggestions on how to
    " detect this better... This probably won't work on non-English systems.
    if l:options =~ "^warning: slocate:"
        throw "LocateOpenError: Something's screwy. Have you run updatedb " .
            \ "recently?"
    endif

    " Do we have no files?
    if l:options == ""
        throw "LocateOpenError: No file found"
    endif

    " We have one or more files
    let l:options_copy = l:options
    let l:i = stridx(l:options, "\n")
    let l:x = 0
    while l:i > -1
        let l:option=strpart(l:options, 0, l:i)
        let l:options=strpart(l:options, l:i+1)
        let l:i = stridx(l:options, "\n")
        let l:x = l:x + 1
        echo l:x . ": " . l:option
    endwhile
    let l:options = l:options_copy
    if l:x > 1
        let l:which=input("Which file? ")
        let l:y = 1
        while l:y <= l:x
            if l:y == l:which
                return strpart(l:options, 0, stridx(l:options, "\n"))
            else
                let l:options=strpart(l:options, stridx(l:options, "\n") + 1)
                let l:y = l:y + 1
            endif
        endwhile
        throw "LocateOpenError: Invalid choice"
    else
        return strpart(l:options_copy, 0, stridx(l:options_copy, "\n"))
    endif
endfun

" Find a file and run :cmd file
function! s:LocateRun(cmd, file)
    try
        let l:options = s:LocateFile(a:file)
        exec a:cmd . ' ' . l:options
    catch /^LocateOpenError: /
        echo " "
        echoerr "Error: " . substitute(v:exception, "^LocateOpenError: ",
            \ "", "")
    endtry
endfun

" Find a file and :edit it
function! LocateEdit(file)
    call s:LocateRun('edit', a:file)
endfun

" Find a file and :split it
function! LocateSplit(file)
    call s:LocateRun('split', a:file)
endfun

" Do magicky export things
command! -nargs=1 LocateEdit   :call LocateEdit(<q-args>)
command! -nargs=1 LocateSplit  :call LocateSplit(<q-args>)

