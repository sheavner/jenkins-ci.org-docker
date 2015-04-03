# BEGIN CUSTOM 
FROM ubuntu:14.04

# docker build --force-rm -t jenkins:lts .
# docker  run --rm -p 8080:8080 -v /mnt/jenkins/var:/var/jenkins_home -v /mnt/jenkins:/mnt/jenkins jenkins:lts

RUN apt-get update && apt-get install -y --no-install-recommends wget git curl zip openssh-client openjdk-6-jdk openjdk-7-jdk ruby python python-pip python-dev build-essential nodejs nodejs-legacy npm && rm -rf /var/lib/apt/lists/*
RUN locale-gen en_US en_US.UTF-8 && dpkg-reconfigure locales
ENV LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
RUN gem install sass
RUN pip install --upgrade pip 
RUN pip install --upgrade virtualenv 

VOLUME /mnt/jenkins

# END CUSTOM

ENV JENKINS_HOME /var/jenkins_home

# Jenkins is ran with user `jenkins`, uid = 1000
# If you bind mount a volume from host/vloume from a data container, 
# ensure you use same uid
RUN useradd -d "$JENKINS_HOME" -u 1000 -m -s /bin/bash jenkins

# Jenkins home directoy is a volume, so configuration and build history 
# can be persisted and survive image upgrades
VOLUME /var/jenkins_home

# `/usr/share/jenkins/ref/` contains all reference configuration we want 
# to set on a fresh new installation. Use it to bundle additional plugins 
# or config file with your custom jenkins Docker image.
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d


COPY init.groovy /usr/share/jenkins/ref/init.groovy.d/tcp-slave-angent-port.groovy

ENV JENKINS_VERSION 1.596.2

# could use ADD but this one does not check Last-Modified header 
# see https://github.com/docker/docker/issues/8331
RUN curl -L http://mirrors.jenkins-ci.org/war-stable/1.596.2/jenkins.war -o /usr/share/jenkins/jenkins.war

ENV JENKINS_UC https://updates.jenkins-ci.org
RUN chown -R jenkins "$JENKINS_HOME" /usr/share/jenkins/ref

# for main web interface:
EXPOSE 8080

# will be used by attached slave agents:
EXPOSE 50000

USER jenkins

COPY jenkins.sh /usr/local/bin/jenkins.sh
ENTRYPOINT ["/usr/local/bin/jenkins.sh"]

# from a derived Dockerfile, can use `RUN plugin.sh active.txt` to setup /usr/share/jenkins/ref/plugins from a support bundle
COPY plugins.sh /usr/local/bin/plugins.sh
