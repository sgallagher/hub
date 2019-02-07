SOURCES = $(shell script/build files)
SOURCE_DATE_EPOCH ?= $(shell date +%s)
BUILD_DATE = $(shell date -u -d "@$(SOURCE_DATE_EPOCH)" '+%d %b %Y' 2>/dev/null || date -u -r "$(SOURCE_DATE_EPOCH)" '+%d %b %Y')
HUB_VERSION = $(shell bin/hub version | tail -1)
FLAGS_ALL = $(shell go version | grep -q 'go1.[89]' || echo 'all=')
export LDFLAGS := -extldflags '$(LDFLAGS)'
export GCFLAGS := $(FLAGS_ALL)-trimpath '$(PWD)'
export ASMFLAGS := $(FLAGS_ALL)-trimpath '$(PWD)'

MIN_COVERAGE = 89.4

HELP_CMD = \
	share/man/man1/hub-alias.1 \
	share/man/man1/hub-api.1 \
	share/man/man1/hub-browse.1 \
	share/man/man1/hub-ci-status.1 \
	share/man/man1/hub-compare.1 \
	share/man/man1/hub-create.1 \
	share/man/man1/hub-delete.1 \
	share/man/man1/hub-fork.1 \
	share/man/man1/hub-pr.1 \
	share/man/man1/hub-pull-request.1 \
	share/man/man1/hub-release.1 \
	share/man/man1/hub-issue.1 \
	share/man/man1/hub-sync.1 \

HELP_EXT = \
	share/man/man1/hub-am.1 \
	share/man/man1/hub-apply.1 \
	share/man/man1/hub-checkout.1 \
	share/man/man1/hub-cherry-pick.1 \
	share/man/man1/hub-clone.1 \
	share/man/man1/hub-fetch.1 \
	share/man/man1/hub-help.1 \
	share/man/man1/hub-init.1 \
	share/man/man1/hub-merge.1 \
	share/man/man1/hub-push.1 \
	share/man/man1/hub-remote.1 \
	share/man/man1/hub-submodule.1 \

HELP_ALL = share/man/man1/hub.1 $(HELP_CMD) $(HELP_EXT)

TEXT_WIDTH = 87

bin/hub: $(SOURCES)
	script/build -o $@

bin/md2roff: $(SOURCES)
	go build -ldflags "-B 0x$(head -c20 /dev/urandom|od -An -tx1|tr -d ' \n')" -o $@ github.com/github/hub/md2roff-bin

test:
	go test ./...

test-all: bin/cucumber
ifdef CI
	script/test --coverage $(MIN_COVERAGE)
else
	script/test
endif

bin/cucumber:
	ln -s /usr/bin/cucumber bin/cucumber

fmt:
	go fmt ./...

man-pages: $(HELP_ALL:=.md) $(HELP_ALL) $(HELP_ALL:=.txt)

%.txt: %
	groff -Wall -mtty-char -mandoc -Tutf8 -rLL=$(TEXT_WIDTH)n $< | col -b >$@

$(HELP_ALL): share/man/.man-pages.stamp
share/man/.man-pages.stamp: $(HELP_ALL:=.md) ./man-template.html bin/md2roff
	bin/md2roff --manual="hub manual" \
		--date="$(BUILD_DATE)" --version="$(HUB_VERSION)" \
		--template=./man-template.html \
		share/man/man1/*.md
	touch $@

%.1.md: bin/hub
	bin/hub help $(*F) --plain-text >$@

share/man/man1/hub.1.md:
	true

install: bin/hub man-pages
	bash < script/install.sh

clean:
	git clean -fdx bin share/man

.PHONY: clean test test-all man-pages fmt install
