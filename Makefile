DIRS=\
	docs \
	test-aftersetbox \
	test-basic \
	test-extern \
	test-ligatures \
	test-subdir/in/side \
	test-titlepage \
	test-verb \
	test-zoom

all: $(addsuffix /slides.md5,$(DIRS))

%/slides.md5: PHONY
	make -C $(dir $@) docker

.PHONY: PHONY
