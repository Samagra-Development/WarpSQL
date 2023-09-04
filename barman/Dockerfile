FROM ubcctlt/barman

RUN apt-get update && \
    apt-get install -y openssh-server && \
    apt-get clean
# Permit root login via SSH
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# SSH port 
EXPOSE 22
COPY barman_entrypoint.sh  /barman_entrypoint.sh
RUN chmod +x /barman_entrypoint.sh
RUN mkdir -p /run/sshd
ENTRYPOINT ["tini","--","/barman_entrypoint.sh"]
CMD ["cron", "-L", "4",  "-f"]