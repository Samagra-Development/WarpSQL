#!/usr/bin/env bash
# copy ssh keys to root and barman users
set -ex
if [ -d "/tmp/ssh/" ]; then
  cp -R /tmp/ssh/ /root/.ssh/
chmod 700 /root/.ssh
chmod 644 /root/.ssh/id_rsa.pub
chmod 600 /root/.ssh/id_rsa
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
cp -R /tmp/ssh/* ~barman/.ssh/
ls -alh ~barman/.ssh/
ls -alh /tmp/ssh/
ls -alh /root/.ssh/
chown barman:barman -R  ~barman/.ssh/ 
    su - barman -c "chmod 700 ~barman/.ssh \
    && chmod 644 ~barman/.ssh/id_rsa.pub \
    && chmod 600 ~barman/.ssh/id_rsa  \
    && cat ~barman/.ssh/id_rsa.pub >> ~barman/.ssh/authorized_keys \
    && chmod 600 ~barman/.ssh/authorized_keys"
/usr/sbin/sshd
fi
exec /entrypoint.sh "$@"