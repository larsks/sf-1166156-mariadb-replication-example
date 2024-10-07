/***********************************************************************
 * To generate compose.yaml from this file:
 *
 *     jsonnet -o compose.yaml compose.jsonnet
 *
 * To enable healthchecks and service dependencies:
 *
 *     jsonnet -o compose.yaml compose.jsonnet --tla-code enable_healthchecks=true
 *
 * To select a different base port for host port mapping:
 *
 *     jsonnet -o compose.yaml compose.jsonnet --tla-code base_port=55300
 ***********************************************************************/


/*
 * This generates the service entry for a mariadb server. It contains the common configuration used
 * by both the primary(...) and replica(...) functions, below.
 */
local node(id, enable_healthchecks=false, base_port=3000) = {
  environment: {
    TZ: '${TZ}',
    MARIADB_ROOT_PASSWORD: '${MARIADB_ROOT_PASSWORD}',
    MARIADB_REPLICATION_USER: '${MARIADB_REPLICATION_USER}',
    MARIADB_REPLICATION_PASSWORD: '${MARIADB_REPLICATION_PASSWORD}',
  },
  hostname: 'mariadb%d' % id,
  image: 'mariadb:10',
  volumes: [
    'mariadb%d:/var/lib/mysql' % id,
  ],
  ports: [
    '127.0.0.1:%d:3306' % (base_port + id),
  ],
  command: [
    '--server-id=%d' % id,
  ],
} + if enable_healthchecks then {
  environment+: {
    MARIADB_MYSQL_LOCALHOST_USER: 'yes',
  },
  healthcheck: {
    test: ['CMD', 'healthcheck.sh', '--su-mysql', '--connect', '--innodb_initialized'],
    start_period: '30s',
    interval: '10s',
    retries: '3',
    timeout: '30s',
  },
} else {};

/*
 * This function generates the service entry for the primary server; it appends
 * the command line arguments necessary to successfully enable replication.
 */
local primary(enable_healthchecks=false, base_port=3000) = node(1, enable_healthchecks=enable_healthchecks, base_port=base_port) {
  command+: [
    '--log-bin',
    '--log-basename=mariadb1',
    '--binlog-format=mixed',
  ],
};

/*
 * This function generates the service entry for the replicas. We set the MARIADB_MASTER_HOST environment variable,
 * which is used by the container image to automatically configure replication (along with the MARIADB_REPLICATION_USER and
 * MARIADB_REPLICATION_PASSWORD variables, which are set for all service entries).
 */
local replica(id, enable_healthchecks=false, base_port=3000) = node(id, enable_healthchecks=enable_healthchecks, base_port=base_port) {
  environment+: {
    MARIADB_MASTER_HOST: '${MARIADB_MASTER_HOST}',
  },
} + if enable_healthchecks then {
  depends_on: {
    mariadb1: {
      condition: 'service_healthy',
    },
  },
} else {};

function(replica_count=2, enable_healthchecks=false, base_port=3000)
  {
    services:
      {
        mariadb1: primary(enable_healthchecks=enable_healthchecks, base_port=base_port),
      } + {
        ['mariadb%d' % (id + 1)]: replica(id + 1, enable_healthchecks=enable_healthchecks, base_port=base_port)
        for id in std.range(1, replica_count)
      },
    volumes: {
      mariadb1: null,
    } + { ['mariadb%d' % (id + 1)]: null for id in std.range(1, replica_count) },
  }
