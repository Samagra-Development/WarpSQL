#!/usr/bin/env bash
# copy ssh keys to root and postgres users
set -ex
if [ -d "/tmp/ssh/" ]; then
    cp -R /tmp/ssh/ /root/.ssh/
    chmod 700 /root/.ssh
    chmod 644 /root/.ssh/id_rsa.pub
    chmod 600 /root/.ssh/id_rsa
    cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    cp -R /tmp/ssh/ ~postgres/.ssh/ 
    echo -e  > ~postgres/.ssh/config "Host *\n\tStrictHostKeyChecking no" # prevent barman commands failing when using ssh
    chown postgres:postgres -R  ~postgres/.ssh/ 
    su - postgres -c "chmod 700 ~postgres/.ssh \
    && chmod 644 ~postgres/.ssh/id_rsa.pub \
    && chmod 600 ~postgres/.ssh/id_rsa  \
    && chmod 600 ~postgres/.ssh/config  \
    && cat ~postgres/.ssh/id_rsa.pub >> ~postgres/.ssh/authorized_keys \
    && chmod 600 ~postgres/.ssh/authorized_keys"
/usr/sbin/sshd #start the ssh server
fi

exec /usr/local/bin/docker-entrypoint.sh "$@"