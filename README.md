myoffice2
---------

Source code for the myoffice2 mod_perl application


## build

```bash
$ docker build -t myoffice2 .
```

## run

```bash
$ docker run -d \
  --name myoffice2 \
  -p 80:80 \
  -e MYSQL_USER=webkitfolders \
  -e MYSQL_PASSWORD=$MYSQL_PASSWORD \
  --link mysql:mysql \
  myoffice2
```

## licence

MIT