SKINK_HOME ?= /usr/local/lib/skink
SKINK = $(SKINK_HOME)/../skink-lang/skink

.PHONY: check build arm

check:
	SKINK_HOME=$(SKINK_HOME) $(SKINK) -check main.skink

build:
	SKINK_HOME=$(SKINK_HOME) $(SKINK) -o distributed main.skink

arm:
	SKINK_HOME=$(SKINK_HOME) $(SKINK) -target aarch64-linux-gnu -o distributed-arm main.skink
