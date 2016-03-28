
default:	build

clean:
	rm -rf Makefile objs

build:
	$(MAKE) -f objs/Makefile
	$(MAKE) -f objs/Makefile manpage

install:
	$(MAKE) -f objs/Makefile install

upgrade:
	/www/nginx/sbin/nginx -t

	kill -USR2 `cat /www/nginx/logs/nginx.pid`
	sleep 1
	test -f /www/nginx/logs/nginx.pid.oldbin

	kill -QUIT `cat /www/nginx/logs/nginx.pid.oldbin`
