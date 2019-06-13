export TEXMFHOME=./texmf/home
export TEXMFCONFIG=./texmf/config
export TEXMFVAR=./texmf/var

all: grid.pdf

# We also commit grid.pdf to git, because it's very small anyways.
grid.pdf: grid.tex
	lualatex grid.tex

clean:
	rm -rf texmf grid.log grid.aux

.PHONY: clean all
