# Use the official MySQL 5.7.31 image as a parent image.
FROM mysql/mysql-server:5.7.31

MAINTAINER Anuj Sehgal <anuj@hokocloud.com>

ADD epel-release-latest-7.noarch.rpm /
RUN yum install -y /epel-release-latest-7.noarch.rpm

#Update packages
RUN yum update -y

#Install SSH
RUN yum install -y openssh-server sudo bash-completion supervisor expect

#Setup SSH
RUN mkdir -p /var/run/sshd ; chmod -rx /var/run/sshd
RUN pass=$(echo date +%s | sha256sum | base64 | head -c 32; echo | mkpasswd) && echo "root:${pass}" | chpasswd
RUN ssh-keygen -A

RUN sed -i 's/#PermitRootLogin no/#PermitRootLogin yes/g' /etc/ssh/sshd_config
RUN sed -i 's/#PermitRootLogin prohibit-password/#PermitRootLogin yes/g' /etc/ssh/sshd_config
RUN sed -ri 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config

RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
RUN sed -ri 's/#UsePAM no/UsePAM no/g' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

ENV NOTVISIBLE="in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22

#Setup MySQL
ADD mysql-ssh.ini /etc/supervisord.d/
ENTRYPOINT ["/usr/bin/supervisord", "-n"]
