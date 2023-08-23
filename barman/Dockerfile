FROM ubcctlt/barman

RUN apt-get update && \
    apt-get install -y openssh-server && \
    apt-get clean

# Set the root password for the SSH server (CHANGE THIS PASSWORD!)
# RUN echo 'root:your_password_here' | chpasswd

# Permit root login via SSH
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Enable password authentication
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# SSH port (optional, change if needed)
EXPOSE 22
# RUN ssh-keygen -A

COPY entrypoint_ssh.sh  /entrypoint_ssh.sh
# RUN mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
RUN chmod +x /entrypoint_ssh.sh
RUN mkdir -p /run/sshd
ENTRYPOINT ["tini","--","/entrypoint_ssh.sh"]
CMD ["cron", "-L", "4",  "-f"]