################################################
SUBDIRS = gserver

all: subdirs

subdirs:
ifeq ($(mode),debug)
		for n in $(SUBDIRS); do cd $$n;$(MAKE) mode=debug -j 60||exit 1;cd -; done
else
		for n in $(SUBDIRS); do cd $$n;$(MAKE) -j 60||exit 1;cd -; done
endif

clean:
	for n in $(SUBDIRS); do cd $$n;$(MAKE) clean;cd -; done
