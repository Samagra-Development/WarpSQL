#!/usr/bin/env bash
set -ex
if [ -d "/tmp/ssh/" ]; then
    cp -R /tmp/ssh/ /root/.ssh/
    chmod 700 /root/.ssh
    chmod 644 /root/.ssh/id_rsa.pub
    chmod 600 /root/.ssh/id_rsa
    cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    cp -R /tmp/ssh/ ~postgres/.ssh/ 
    chown postgres:postgres -R  ~postgres/.ssh/ 
    su - postgres -c "chmod 700 ~postgres/.ssh \
    && chmod 644 ~postgres/.ssh/id_rsa.pub \
    && chmod 600 ~postgres/.ssh/id_rsa  \
    && cat ~postgres/.ssh/id_rsa.pub >> ~postgres/.ssh/authorized_keys \
    && chmod 600 ~postgres/.ssh/authorized_keys"
/usr/sbin/sshd
fi

exec /usr/local/bin/docker-entrypoint.sh "$@"