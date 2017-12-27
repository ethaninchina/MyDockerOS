# MySQL Replication Master/Slave cluster example

One of the most common feature requested for the MySQL docker official image is adding replication master/slave ability. As docker-library/mysql#43 is closed by deciding that it's a feature should be implemented via `init` script, my example here is a demo of how to do it.

The official MySQL image have the customize ability by running script files under `/docker-entrypoint-initdb.d/` directory. The script has to be either a shell script, `.sh`, or a SQL script, `.sql` or `.sql.gz`.

To implement the MySQL replication, I borrowed the code from PR: docker-library/mysql#43, modified and saved as `replica.sh`. As described in the script comments, we have 5 more special environment variables for replication.

- `MYSQL_REPLICA_USER`: create the given user on the intended master host
- `MYSQL_REPLICA_PASS`
- `MYSQL_MASTER_SERVER`: change master on this location on the intended slave
- `MYSQL_MASTER_PORT`: optional, by default 3306
- `MYSQL_MASTER_WAIT_TIME`: seconds to wait for the master to come up

The `Dockerfile` is very simple, just copied `replica.sh` to `/docker-entrypoint-initdb.d/` directory. That's it.

> The reason why I create a new Docker image here, instead of mount the file directly into container during the runtime, is that, it's not easy to maintain the updated file across the cluster. Put it into the Docker image is best way to handle such static config file in cluster environment.

To build the image just:

```bash
docker build -t twang2218/mysql:5.7-replica .
```

*Replace `twang2218` with your docker username*

Then push the image to the Docker Hub, so it can be used across cluster.

```bash
docker push twang2218/mysql:5.7-replica
```

Then, let's use the new MySQL image with replication ability. To do that, I created a simple `docker-compose.yml` file:

```yaml
version: '2'
services:
    master:
        image: twang2218/mysql:5.7-replica
        restart: unless-stopped
        ports:
            - 3306:3306
        environment:
            - MYSQL_ROOT_PASSWORD=master_passw0rd
            - MYSQL_REPLICA_USER=replica
            - MYSQL_REPLICA_PASS=replica_Passw0rd
        command: ["mysqld", "--log-bin=mysql-bin", "--server-id=1"]
    slave:
        image: twang2218/mysql:5.7-replica
        restart: unless-stopped
        ports:
            - 3307:3306
        environment:
            - MYSQL_ROOT_PASSWORD=slave_passw0rd
            - MYSQL_REPLICA_USER=replica
            - MYSQL_REPLICA_PASS=replica_Passw0rd
            - MYSQL_MASTER_SERVER=master
            - MYSQL_MASTER_WAIT_TIME=10
        command: ["mysqld", "--log-bin=mysql-bin", "--server-id=2"]
```

Then, just simply run it by `docker-compose up -d`, then our MySQL replication master and slave are running. Feel free to create something on the master and check whether it's been replicated to the slave.
