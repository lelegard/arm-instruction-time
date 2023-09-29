#----------------------------------------------------------------------------
# Copyright (c) 2023, Thierry Lelegard
# BSD 2-Clause License, see LICENSE file.
#----------------------------------------------------------------------------

SRCDIR   = .
BINDIR   = build
EXEC     = $(BINDIR)/instime
CFLAGS  += -Werror -Wall -Wextra -Wno-unused-parameter $(if $(DEBUG),-g,-O2)
NAME	 = $(notdir $(PWD))
TMPFILES = build *.tmp *.log *.tgz

default: $(EXEC)
run: $(EXEC)
	$(EXEC)
$(EXEC): $(BINDIR)/instime.o $(BINDIR)/inscode.o
	$(CC) $(LDFLAGS) $^ $(LDLIBS) -o $@
$(BINDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(BINDIR)
	$(CC) $(CFLAGS) $(CPPFLAGS) -c -o $@ $<
$(BINDIR)/%.o: $(SRCDIR)/%.S
	@mkdir -p $(BINDIR)
	$(CC) $(CPPFLAGS) $(if $(findstring Linux,$(shell uname -s)),-march=armv8.3-a) -c -o $@ $<
tarball:
	tar czf $(NAME).tgz -C .. $(addprefix --exclude ,.git $(TMPFILES)) $(NAME)
clean:
	rm -rf $(TMPFILES)
