
# Makefile for the Non-DAW.
# Copyright 2008 Jonathan Moore Liles
# This file is licensed under version 2 of the GPL.

#
# Do not edit this file; run `make config` instead.
#

VERSION := 0.5.0

all: .config FL Timeline

.config: configure
	@ ./configure

config:
	@ ./configure

-include .config

# a bit of a hack to make sure this runs before any rules
ifneq ($(CALCULATING),yes)
TOTAL := $(shell $(MAKE) CALCULATING=yes -n 2>/dev/null | sed -n 's/^.*Compiling: \([^"]\+\)"/\1/p' > .files )
endif

ifeq ($(USE_DEBUG),yes)
	CXXFLAGS := -pipe -ggdb -Wall -Wextra -Wnon-virtual-dtor -Wno-missing-field-initializers -O0 -fno-rtti -fno-exceptions
else
	CXXFLAGS := -pipe -O2 -fno-rtti -fno-exceptions -DNDEBUG
endif

CXXFLAGS += $(SNDFILE_CFLAGS) $(LASH_CFLAGS) $(FLTK_CFLAGS) -DINSTALL_PREFIX="\"$(prefix)\"" -DVERSION=\"$(VERSION)\"
INCLUDES := -I. -Iutil -IFL

include scripts/colors

ifneq ($(CALCULATING),yes)
	COMPILING="$(BOLD)$(BLACK)[$(SGR0)$(CYAN)`scripts/percent-complete .files "$<"`$(SGR0)$(BOLD)$(BLACK)]$(SGR0) Compiling: $(BOLD)$(YELLOW)$<$(SGR0)"
else
	COMPILING="Compiling: $<"
endif

.C.o:
	@ echo $(COMPILING)
	@ $(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

%.C : %.fl
	@ cd `dirname $<` && fluid -c ../$<

DONE := $(BOLD)$(GREEN)done$(SGR0)

include FL/makefile.inc
include Timeline/makefile.inc

SRCS:=$(Timeline_SRCS) $(FL_SRCS)
OBJS:=$(FL_OBJS) $(Timeline_OBJS)

# FIXME: isn't there a better way?
$(OBJS): .config

TAGS: $(SRCS)
	etags $(SRCS)

.deps: .config $(SRCS)
	@ echo -n Calculating dependencies...
	@ makedepend -f- -- $(CXXFLAGS) $(INCLUDES) -- $(SRCS) > .deps 2>/dev/null && echo $(DONE)

clean_deps:
	@ rm -f .deps

.PHONEY: clean config depend clean_deps

clean: FL_clean Timeline_clean

dist:
	git archive --prefix=non-daw-$(VERSION)/ v$(VERSION) | bzip2 > non-daw-$(VERSION).tar.bz2

-include .deps
