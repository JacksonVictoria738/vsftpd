# Makefile for vsftpd
# Supports native build and cross-compilation.
#
# Cross-compilation example (ARMv7 uClibc):
#   make CC=arm-buildroot-linux-uclibcgnueabihf-gcc LIBS= STATIC=1
#
# Native build with PAM/SSL:
#   make                    (uses vsf_findlibs.sh to detect libraries)

# Compiler and tools
CC       ?= gcc
INSTALL  ?= install

# Extra include paths for dummy headers (fallback when system lacks headers)
IFLAGS    = -idirafter dummyinc

# Base CFLAGS
# Note: -fstack-protector and -D_FORTIFY_SOURCE are NOT in defaults because
# uClibc/musl toolchains lack libssp and fortified source support.
# Set HARDENING=1 to re-enable them for glibc native builds.
CFLAGS   ?= -O2 -fPIE -Wall -W -Wshadow -Werror

# Optional security hardening (glibc only, needs libssp)
ifeq ($(HARDENING),1)
  CFLAGS   += -fstack-protector --param=ssp-buffer-size=4 -D_FORTIFY_SOURCE=2 \
              -Wformat-security
endif

# Strip -Werror for cross-compilation (set NOWERROR=1)
ifeq ($(NOWERROR),1)
  CFLAGS   := $(filter-out -Werror,$(CFLAGS))
endif

# Additional user CFLAGS (use EXTRA_CFLAGS from command line)
CFLAGS   += $(EXTRA_CFLAGS)

# Libraries — runs vsf_findlibs.sh for native builds.
# For cross-compilation / embedded, set LIBS= to skip library detection.
LIBS     ?= `./vsf_findlibs.sh`

# Linker flags
LDFLAGS  ?= -fPIE -pie -Wl,-z,relro -Wl,-z,now

# Static build (set STATIC=1 for fully static binary)
ifeq ($(STATIC),1)
  LDFLAGS  += -static
  # PIE + static doesn't make sense, drop -pie/-fPIE
  CFLAGS   := $(subst -fPIE,-fPIC,$(CFLAGS))
  CFLAGS   := $(subst -fpie,,$(CFLAGS))
endif

# Object files
OBJS = main.o utility.o prelogin.o ftpcmdio.o postlogin.o privsock.o \
       tunables.o ftpdataio.o secbuf.o ls.o \
       postprivparent.o logging.o str.o netstr.o sysstr.o strlist.o \
       banner.o filestr.o parseconf.o secutil.o \
       ascii.o oneprocess.o twoprocess.o privops.o standalone.o hash.o \
       tcpwrap.o ipaddrparse.o access.o features.o readwrite.o opts.o \
       ssl.o sslslave.o ptracesandbox.o ftppolicy.o sysutil.o sysdeputil.o \
       seccompsandbox.o

# Default target
all: vsftpd

.c.o:
	$(CC) -c $*.c $(CFLAGS) $(IFLAGS)

vsftpd: $(OBJS)
	$(CC) -o vsftpd $(OBJS) $(LDFLAGS) $(LIBS)

# Show build configuration
show-config:
	@echo "CC       = $(CC)"
	@echo "CFLAGS   = $(CFLAGS)"
	@echo "LDFLAGS  = $(LDFLAGS)"
	@echo "LIBS     = $(LIBS)"
	@echo "STATIC   = $(STATIC)"

install:
	if [ -x /usr/local/sbin ]; then \
		$(INSTALL) -m 755 vsftpd /usr/local/sbin/vsftpd; \
	else \
		$(INSTALL) -m 755 vsftpd /usr/sbin/vsftpd; fi
	if [ -x /usr/local/man ]; then \
		$(INSTALL) -m 644 vsftpd.8 /usr/local/man/man8/vsftpd.8; \
		$(INSTALL) -m 644 vsftpd.conf.5 /usr/local/man/man5/vsftpd.conf.5; \
	elif [ -x /usr/share/man ]; then \
		$(INSTALL) -m 644 vsftpd.8 /usr/share/man/man8/vsftpd.8; \
		$(INSTALL) -m 644 vsftpd.conf.5 /usr/share/man/man5/vsftpd.conf.5; \
	else \
		$(INSTALL) -m 644 vsftpd.8 /usr/man/man8/vsftpd.8; \
		$(INSTALL) -m 644 vsftpd.conf.5 /usr/man/man5/vsftpd.conf.5; fi
	if [ -x /etc/xinetd.d ]; then \
		$(INSTALL) -m 644 xinetd.d/vsftpd /etc/xinetd.d/vsftpd; fi

clean:
	rm -f *.o *.swp vsftpd

.PHONY: all clean install show-config
