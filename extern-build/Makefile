export TEXMFHOME=./texmf/home
export TEXMFCONFIG=./texmf/config
export TEXMFVAR=./texmf/var
LUATEX=luatex --file-line-error --halt-on-error --interaction=nonstopmode --shell-escape
NICS_FMTDEPS=$(foreach d,../src, \
	$d/nics-cached.tex \
	$d/nics-fonts.tex \
	$d/nics-extern.tex \
	$d/nics-colors.tex \
	$d/nics-outline.tex \
	$d/nics-content.tex \
	$d/nics-aftersetbox.tex \
	$d/nics-zoom.tex \
	$d/nics-verb.tex \
	$d/nics-slide.tex \
	$d/nics-messages.lua \
	$d/nics-fonts.lua \
)

all: default.fmt tcolorbox.fmt tikz.fmt bgpic.fmt code.fmt

%.fmt: %.tex ${NICS_FMTDEPS}
	@echo Compiling format for extern-build/$(basename $<)
	$(LUATEX) --ini --jobname=$(basename $<) "&lualatex" mylatexformat.ltx $< >$(basename $<).stdouterr 2>&1 || { rm -f $@ ; false ; }
	zcat $@ >$@.tmp && mv $@.tmp $@  # Make fmt reuse fast: get rid of compression

%.pdf: %.tex all
	@echo Compiling sub-job extern-build/$(basename $<)
	$(LUATEX) '&$(TEMPLATE)' $< >$(basename $<).stdouterr 2>&1 || { cat $(basename $<).stdouterr; false; }

clean:
	rm -rf *.aux *.log *.pdf *.pgf *.fmt *.stdouterr *.out *.tex.before [0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]*tex failed.log failed.tex failed.pdf texmf

.PHONY: clean
