# Nilcons Slides - quality presentations from code

With nics you can build slideshows that can achieve the same graphical appeal as PowerPoint or Google Slides,
while still maintaining the source code in text and not in binary.

If you already use Markdown, RST or asciidoc to create your presentations,
you will find nics very familiar, just more powerful.

If you have only used WYSIWYG systems (PowerPoint or Google Slides),
but you are a programmer and familiar with the concept of source code,
then you should definitely give nics a try.

If you have only used graphical systems and you don't want to learn to edit a text file,
then nics is not useful for you.

## TLDR

Web: [https://nics.nilcons.com](https://nics.nilcons.com)

Capability demonstration: [https://github.com/nilcons/nics-hello/blob/master/demo/slides.pdf](https://mozilla.github.io/pdf.js/web/viewer.html?file=https://raw.githubusercontent.com/nilcons/nics-hello/master/demo/slides.pdf)
(source code: [https://github.com/nilcons/nics-hello/blob/master/demo/slides.tex](https://github.com/nilcons/nics-hello/blob/master/demo/slides.tex))

Detailed documentation: [https://github.com/nilcons/nics/blob/examples/docs/slides.pdf](https://mozilla.github.io/pdf.js/web/viewer.html?file=https://media.githubusercontent.com/media/nilcons/nics/examples/docs/slides.pdf)
(source code: [https://github.com/nilcons/nics/blob/examples/docs/slides.tex](https://github.com/nilcons/nics/blob/examples/docs/slides.tex))

A one slide long, minimal document looks like this:

```tex
%% -*- latex -*-
\newtoks\nicsroot\directlua{ tex.settoks("nicsroot", os.getenv("NICS_ROOT") or error("NICS_ROOT environment variable has to be set, use the Makefile")) }
\input{\the\nicsroot /src/nics-cached.tex}
\endofdump
\input{\the\nicsroot /src/nics-noncached.tex}

\hypersetup{pdftitle={Basic nics tests}}

\begin{document}

\begin{slide}{Basic test}{Just one slide with the basics}
  \begin{nicscolumn}[10cm]
    \nicspar{One paragraph}
    \nicsitem{
      One point, that is quite long and therefore has to
      be wrapped by \TeX\ as always with long lines
    }
    \nicsitem{Another point}
    \nicspar{\just
      This would be justified if long enough!
      Wait, maybe we can make it long enough,
      we just have to be relentless in writing up stupid stuff.
    }
    \nicsheader{Moving on...}
    \nicsitem{\nicslonghbox{
      With a hack, a longer line is possible than the
      \mono{\bs hsize} of the \mono{nicscolumn}
    }}
    \begin{nicsindent}
      \small
      \nicsitem{You can use this hack with figures}
      \nicsitem{But don't be proud of hacks!}
    \end{nicsindent}
    \nicsitem{Bye bye now}
  \end{nicscolumn}
  \begin{nicscolumn*}{10cm}{7cm}{3cm}
    \tiny\nicsitem{\tiny Absolute positioning}
  \end{nicscolumn*}
\end{slide}

\end{document}
```

## Getting started

To get started, you should clone the `nics-hello` repository, that can be found at
[https://github.com/nilcons/nics-hello](https://github.com/nilcons/nics-hello).

    git clone --recurse-submodules git://github.com/nilcons/nics-hello

Then you should go to the directory called `demo` and run `make docker` (or
`make` if you have all the [Dependencies](https://github.com/nilcons/nics/blob/docker/Dockerfile) installed on your machine).

    cd nics-hello/demo
    make docker

Once you confirmed that you can re-build the `demo/slides.pdf`,
you are ready to make modifications to `demo/slides.tex` and re-build.
Keep the `demo/slides.pdf` open in evince or another PDF viewer to get instant feedback.

The first build takes some time, but re-builds after small modifications should take less than a second.

## Reference documentation

After using `nics-hello` to get an initial feel to the system, you might want to read the more detailed documentation.

This explains the LaTeX and LuaTeX concepts behind nics and gives a better overview of the feature set.

    git clone -b examples --recurse-submodules git://github.com/nilcons/nics
    cd nics/docs
    make docker
    evince slides.pdf

If you don't want to build it, you can also simply read it on the web:
[https://github.com/nilcons/nics/blob/examples/docs/slides.pdf](https://mozilla.github.io/pdf.js/web/viewer.html?file=https://media.githubusercontent.com/media/nilcons/nics/examples/docs/slides.pdf)
(source code: [https://github.com/nilcons/nics/blob/examples/docs/slides.tex](https://github.com/nilcons/nics/blob/examples/docs/slides.tex))

## Wait, this is a LaTeX based system, scary!

Yeah, but we keep the LaTeX knowledge required to the minimum.
If you read through the getting started document, you will be ready to go.

If you can't solve your problem even after reading the reference documentation, then please get in touch via the issue tracker!
