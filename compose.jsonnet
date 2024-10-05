local node(id, add_healthchecks=false) = {
  environment: {
    TZ: '${TZ}',
    MARIADB_ROOT_PASSWORD: '${MARIADB_ROOT_PASSWORD}',
    MARIADB_REPLICATION_USER: '${MARIADB_REPLICATION_USER}',
    MARIADB_REPLICATION_PASSWORD: '${MARIADB_REPLICATION_PASSWORD}',
    MARIADB_MYSQL_LOCALHOST_USER: 'yes',
  },
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
  ],
} + if add_healthchecks then {
  healthcheck: {
    test: ['CMD', 'healthcheck.sh', '--su-mysql', '--connect', '--innodb_initialized'],
    start_period: '30s',
    interval: '10s',
    retries: '3',
    timeout: '30s',
  },
} else {};

local primary(add_healthchecks=false) = node(1, add_healthchecks=add_healthchecks) {
  command+: [
    '--log-bin',
    '--log-basename=mariadb1',
    '--binlog-format=mixed',
  ],
};

local replica(id, add_healthchecks=false) = node(id, add_healthchecks=add_healthchecks) {
  environment+: {
    MARIADB_MASTER_HOST: '${MARIADB_MASTER_HOST}',
  },
} + if add_healthchecks then {
  depends_on: {
    mariadb1: {
      condition: 'service_healthy',
    },
  },
} else {};

function(replica_count=2, add_healthchecks=false)
  {
    services:
      {
        mariadb1: primary(add_healthchecks=add_healthchecks),
      } + { ['mariadb%d' % (id + 1)]: replica(id + 1, add_healthchecks=add_healthchecks) for id in std.range(1, replica_count) },
    volumes: {
      mariadb1: null,
    } + { ['mariadb%d' % (id + 1)]: null for id in std.range(1, replica_count) },
  }
