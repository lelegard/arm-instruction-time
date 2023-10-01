#----------------------------------------------------------------------------
# Copyright (c) 2023, Thierry Lelegard
# BSD 2-Clause License, see LICENSE file.
#----------------------------------------------------------------------------

SRCDIR   = .
BINDIR   = build
EXEC     = $(BINDIR)/instime
SYSTEM  := $(subst Linux,linux,$(subst Darwin,mac,$(shell uname -s)))
CFLAGS  += -Werror -Wall -Wextra -Wno-unused-parameter $(if $(DEBUG),-g,-O2)
NAME	 = $(notdir $(PWD))
TMPFILES = build *.tmp *.log *.tgz

ifeq ($(SYSTEM),mac)
    # On Mac, force arm64e architecture when enabled on the current system.
    ARCHFLAGS := $(if $(shell (uname -m | grep arm64e) || ((csrutil status | grep disabled) && (nvram -p | grep '^boot-args.*-arm64e_preview_abi'))),-arch arm64e)
    ASMFLAGS := $(ARCHFLAGS)
else
    # On Linux, force armv8.3 to compile PAC instructions in assembly code.
    ARCHFLAGS :=
    ASMFLAGS := -march=armv8.3-a
endif

default: $(EXEC)
run: $(EXEC)
	$(EXEC)
$(EXEC): $(BINDIR)/instime.o $(BINDIR)/inscode.o
	$(CC) $(LDFLAGS) $(ARCHFLAGS) $^ $(LDLIBS) -o $@
$(BINDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(BINDIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) $(ARCHFLAGS) -c -o $@ $<
$(BINDIR)/%.o: $(SRCDIR)/%.S
	@mkdir -p $(BINDIR)
	$(CC) $(CPPFLAGS) $(ASMFLAGS) -c -o $@ $<
tarball:
	tar czf $(NAME).tgz -C .. $(addprefix --exclude ,.git $(TMPFILES)) $(NAME)
clean:
	rm -rf $(TMPFILES)
