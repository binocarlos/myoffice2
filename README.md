myoffice2
---------

Source code for the myoffice2 mod_perl application


## build

```bash
$ docker build -t myoffice2 .
```

## run

```bash
$ docker run -ti --rm \
	-v /srv/projects/myoffice2:/home/webkitapps \
	-v /srv/projects/myoffice2:/etc/apache2/sites-enabled/myoffice2.conf \
	-v /var/log/upstart/myoffice2.log:/var/log/access.log \
	myoffice2
```


docker run -ti --rm -v /srv/projects/myoffice2/start.sh:/start.sh -v /srv/projects/myoffice2:/home/webkitapps -v /srv/projects/myoffice2/myoffice2.conf:/etc/apache2/sites-enabled/myoffice2.conf -v /var/log/upstart/myoffice2.log:/var/log/access.log -p 80:80 -e MYSQL_USER=webkitfolders -e MYSQL_PASSWORD=pT5f9zr --link mysql:mysql --entrypoint="bash" myoffice2


## licence

MIT