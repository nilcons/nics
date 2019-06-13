#!/bin/bash

# TODO(errgelow): horrible, rewrite this in Lua

# Okay, so this is a little bit complicated, sorry about that.
#
# The general idea is the following:
#   - we get an input file (filename: $1.before) that was read by LuaTex
#   - $2 is the syntax that we should use for highlighting, we just pass this to pygmentize (e.g. yaml or Dockerfile)
#   - we need to gobble initial spaces
#   - the output from pygmentize is not the best latex:
#     - documentclass{article} is too bloaty, we replace with minimal
#     - we add lualatex compatibility (removing inputenc and section*, adding luacode)
#     - we add \endofdump, so that we can use our code.fmt format (cache)
#   - we play with boxes, so we can set pagewidht and pageheight to be as tight as possible
#     (remember, we are preparing a PDF for an \includegraphics, so we shouldn't output A4 pages)
#
# The big complication comes from the requirement that we would like
# to have a LaTeX escape with the section sign (§).  pygmentize has
# support for LaTeX escaping, but its implementation is completely
# broken, as documented by the following URLs:
#   - https://github.com/gpoore/minted/issues/70
#   - https://github.com/gpoore/minted/commit/f43258974ddd9b1cc02a80bc3ea7595c900a527d
#   - https://bitbucket.org/birkenfeld/pygments-main/issues/1118/escapeinside-is-fragile-with-some-lexers
#   - https://bitbucket.org/birkenfeld/pygments-main/issues/1303/latex-formatter-produces-incorrect-output
#
# Unfortunately pygmentize looks to be not so much maintained anymore
# and I don't see any progress on these bugs, this makes depending on
# `escapeinside' not feasible for now.  (We did that in our first
# implementation and we have been hit by these bugs...)
#
# So instead of using the `escapeinside' feature, we cook our own,
# which is easiest to explain with an example YAML input:
#
#   foo: bar
#   foo: { bar: true } §\textsf{\textbf{← YAML supports one-liners too!}}
#
# What we do with this input is the following:
#  - we only allow escaping at end-of-lines, not in the middle
#  - we send lines to pygmentize without the escaped content (so we sed s/§.*//)
#  - pygmentize writes to TeX \box1
#  - we create a TeX \box2 with the following content:
#      \vbox{\normalsize\ttfamily%
#        \hbox{{\strut\phantom{foo~~bar}}}
#        \hbox{{\strut\phantom{foo~~~~bar~~true~~~}}\textsf{\textbf{← YAML supports one-liners too!}}}
#      }
#    so this is just a box, where the special stuff is there, but
#    the code is all in phantom (and special chars are replaced with ~)
#    (note: we can't replace all with ~, because some accented chars are taller than a \strut, e.g. CAFFÉ)
#  - then we lay \box1 and \box2 on top of each other
#  - and add the nicslightblue background with a colorbox around it
#  - this is our final rendering
#  - these two boxes align perfectly if (these are our assumptions):
#    - pygmentize always outputs line-by-line (checked with very long lines)
#    - pygmentize only changes colors and font style (bold, italic), not font size
#    - we only want to highlight with monospace stuff
#    - all lines in both boxes contain a \strut (we add these ourselves)

set -e
set -u
set -o pipefail
set -E

# To make sed correct with accented characters
# This has been tested on Debian and Arch, maybe we need extra magic on other distros...
export LC_CTYPE=C.UTF-8 2>/dev/null
if [[ $(locale -k charmap 2>/dev/null) != 'charmap="UTF-8"' ]]; then
    export LC_CTYPE=en_US.UTF-8
fi

GOBBLESPACES=$(cat $1.before | head -n1 | tr -d '\n' | sed 's/^\( *\).*/\1/' | wc -c)
{
    echo '\documentclass{minimal}'
    echo '\endofdump'
    echo '\AtBeginDocument{'
    echo '\setbox2=\vbox{\normalsize\ttfamily%'
    cat $1.before | sed "s/^ \{0,$GOBBLESPACES\}//" | while IFS= read -r L ; do
        echo "\hbox{{\strut\phantom{$(echo "$L" | sed 's/§.*//;s/[^[:alnum:]]/~/g')}}$(echo "$L" | sed -n '/§/ {s/.*§//;p}')}"
    done
    echo '}\setbox1=\hbox\bgroup}'
    echo '\AtEndDocument{\egroup\wd1=\wd2\ht2=\ht1\dp2=\dp1\wd2=0pt\relax\setbox0=\hbox{\colorbox{AliceBlue}{\box2\box1}}\pagewidth\wd0\pageheight\dimexpr\ht0+\dp0\relax\shipout\box0}'

    cat $1.before | sed "s/^ \{0,$GOBBLESPACES\}//" | sed 's/§.*//' \
      | pygmentize -l $2 -f tex -O full -O envname=BVerbatim \
      | fgrep -v '\documentclass{article}' \
      | grep -v '\\usepackage.*{inputenc}' \
      | fgrep -v '\section*{}' \
      | sed '/^\\begin{BVerbatim}/,/^\\end{BVerbatim}/ {/^\\begin{BVerbatim}/b ; /^\\end{BVerbatim}/b ; s/^/\\strut{}/}' # the {} after \strut is needed, to make sure that TeX doesn't read it as \strutint if the line starts with "int a;" for example in a C file
} >>$1  # We append, because nicsextern puts in a comment that is useful for the enduser

exit 0
