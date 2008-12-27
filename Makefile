HOST = i386-mingw32
BUILD = i686-apple-darwin8
TARGET = $(HOST)
CC = $(HOST)-gcc
RUBYTARGZ=extra/ruby-1.8.7-p72.tar.gz
INSTALLDIR=$(PWD)/bin/ruby-mingw32

#Used to fool mkmf.rb while compiling exts
TMP_ROOT=$(PWD)/tmp

INCFLAGS = -I. -Iruby-src
PREFLAGS = -DHAVE_PBORCA_H -DRUBY_EXTERN='extern __declspec(dllimport)'
CFLAGS = -g -O2 

LIBPATH =  -L. -Lruby-src
LDFLAGS = -shared -s -Wl,--enable-auto-image-base,--enable-auto-import
LDLIBS = -lpborca -lshell32 -lwsock32 -lmsvcrt-ruby18.dll

stamps/ruby-mingw32: stamps/ruby-config
	#That is the magic rule to build default extensions
	mkdir -p $(TMP_ROOT)/lib/ruby/1.8
	ln -s $(PWD)/ruby-src $(TMP_ROOT)/lib/ruby/1.8/$(TARGET)
	#Build ruby
	(cd ruby-src && make)
	touch stamps/ruby-mingw32

stamps/ruby-config: stamps/ruby-src 
	(cd ruby-src && \
	env \
		ac_cv_func_getpgrp_void=no \
      		ac_cv_func_setpgrp_void=yes \
      		rb_cv_negative_time_t=no \
      		ac_cv_func_memcmp_working=yes \
      		rb_cv_binary_elf=no \
      	./configure \
      		--host=$(HOST) \
		--build=$(BUILD) \
		--target=$(TARGET) \
      		--prefix=$(TMP_ROOT) \
		--with-winsock2 )
	touch stamps/ruby-config

stamps/ruby-src:
	tar zxfv $(RUBYTARGZ)
	x=`echo '$(RUBYTARGZ)' | sed -E 's,.*\/(.*)\.tar\.gz,\1,'`;mv $$x ruby-src
	patch ruby-src/mkconfig.rb extra/mkconfig.patch
	mkdir -p stamps
	touch stamps/ruby-src

#Installs our compiled ruby into INSTALLDIR
.PHONY: install
install: stamps/ruby-mingw32
	(cd ruby-src && \
	cp rbconfig.rb rbconfig.rb.orig && \
	sed -iE 's/CONFIG\["prefix"\].*/CONFIG["prefix"] = DESTDIR/' rbconfig.rb &&\
	make DESTDIR=$(INSTALLDIR) install && \
	mv rbconfig.rb.orig rbconfig.rb)

.PHONY: clean
clean:
	-rm *~
	-rm -r ruby-src
	-rm -r stamps
	-rm -r $(TMP_ROOT)
