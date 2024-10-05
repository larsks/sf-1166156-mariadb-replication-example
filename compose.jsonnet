local node_count = 3;

// set add_healthchecks to true to add healthchecks and dependencies to ensure that the primary
// always starts before the replicas. This does not appear to be necessary in practice.
local add_healthchecks = false;

local node(id) = {
  environment: {
    TZ: '${TZ}',
    MARIADB_ROOT_PASSWORD: '${MARIADB_ROOT_PASSWORD}',
    MARIADB_REPLICATION_USER: '${MARIADB_REPLICATION_USER}',
    MARIADB_REPLICATION_PASSWORD: '${MARIADB_REPLICATION_PASSWORD}',
    MARIADB_MYSQL_LOCALHOST_USER: 'yes',
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
} + if add_healthchecks then {
  healthcheck: {
    test: ['CMD', 'healthcheck.sh', '--su-mysql', '--connect', '--innodb_initialized'],
    start_period: '30s',
    interval: '10s',
    retries: '3',
    timeout: '30s',
  },
} else {} + if add_healthchecks && id != 1 then {
  depends_on: {
    mariadb1: {
      condition: 'service_healthy',
    },
  },
} else {}
;

{
  services:
    { ['mariadb%d' % id]: node(id) for id in std.range(1, node_count) },
  volumes:
    { ['mariadb%d' % id]: null for id in std.range(1, node_count) },
}
