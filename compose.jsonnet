// docker run -e TZ=America/Denver --name mariadb1 --network=camino_nw -e MARIADB_SERVER_ID=1 -e MARIADB_LOG_BIN=mysql-bin -e MARIADB_LOG_BASENAME=mariadb1 -e MARIADB_BINLOG_FORMAT=mixed -p 127.0.0.1:53301:3306 -v /home/jcz/Documents/dockerMariadbData1:/var/lib/mysql:z -e MARIADB_ROOT_PASSWORD=S3cretPw -d mariadb:latest
// docker run -e TZ=America/Denver --name mariadb2 --network=camino_nw -e MARIADB_SERVER_ID=2 -e MARIADB_LOG_BIN=mysql-bin -e MARIADB_LOG_BASENAME=mariadb2 -e MARIADB_BINLOG_FORMAT=mixed -p 127.0.0.1:53302:3306 -v /home/jcz/Documents/dockerMariadbData2:/var/lib/mysql:z -e MARIADB_ROOT_PASSWORD=S3cretPw -d mariadb:latest
// docker run -e TZ=America/Denver --name mariadb3 --network=camino_nw -e MARIADB_SERVER_ID=3 -e MARIADB_LOG_BIN=mysql-bin -e MARIADB_LOG_BASENAME=mariadb3 -e MARIADB_BINLOG_FORMAT=mixed -p 127.0.0.1:53303:3306 -v /home/jcz/Documents/dockerMariadbData3:/var/lib/mysql:z -e MARIADB_ROOT_PASSWORD=S3cretPw -d mariadb:latest

local nodes = 3;

local node(id) = {
  environment: {
    TZ: '${TZ}',
    MARIADB_ROOT_PASSWORD: '${MARIADB_ROOT_PASSWORD}',
    MARIADB_REPLICATION_USER: '${MARIADB_REPLICATION_USER}',
    MARIADB_REPLICATION_PASSWORD: '${MARIADB_REPLICATION_PASSWORD}',
  } + if id != 1 then { MARIADB_MASTER_HOST: '${MARIADB_MASTER_HOST}' } else {},
  hostname: 'mariadb%d' % id,
  image: 'mariadb:10',
  volumes: [
    'mariadb%d:/var/lib/mysql' % id,
  ],
  ports: [
    '127.0.0.1:%d:3306' % (3000 + id),
  ],
  command: [
    '--server-id=%d' % id,
  ] + if id == 1 then [
    '--log-bin',
    '--log-basename=mariadb%d' % id,
    '--binlog-format=mixed',
  ] else [],
};

{
  services:
    { ['mariadb%d' % id]: node(id) for id in std.range(1, nodes) },
  volumes:
    { ['mariadb%d' % id]: null for id in std.range(1, nodes) },
}
