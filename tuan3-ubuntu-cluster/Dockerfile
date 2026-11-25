FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HADOOP_VERSION=3.3.6
ENV SPARK_VERSION=3.5.3
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV HADOOP_HOME=/usr/local/hadoop
ENV SPARK_HOME=/home/hadoopuser/spark-3.5.3
ENV PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin

# Cai dat SSH, Java 11, Python 3 va cong cu co ban
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    openssh-client \
    openjdk-11-jdk \
    python3 \
    python-is-python3 \
    curl \
    wget \
    vim \
    sudo \
    iproute2 \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# Tao user hadoopuser (Buoc 14)
RUN useradd -m -s /bin/bash hadoopuser \
    && echo "hadoopuser:hadoopuser" | chpasswd \
    && usermod -aG sudo hadoopuser \
    && echo "hadoopuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Cau hinh SSH server va tao cap khoa SSH dung chung cho 3 node (Buoc 4, 5, 20, 21)
RUN mkdir -p /var/run/sshd /home/hadoopuser/.ssh \
    && ssh-keygen -t rsa -P "" -f /home/hadoopuser/.ssh/id_rsa \
    && cat /home/hadoopuser/.ssh/id_rsa.pub >> /home/hadoopuser/.ssh/authorized_keys \
    && printf "Host *\n  StrictHostKeyChecking no\n  UserKnownHostsFile=/dev/null\n" > /home/hadoopuser/.ssh/config \
    && chmod 700 /home/hadoopuser/.ssh \
    && chmod 600 /home/hadoopuser/.ssh/authorized_keys /home/hadoopuser/.ssh/config \
    && chown -R hadoopuser:hadoopuser /home/hadoopuser/.ssh

# Tai va cai dat Hadoop 3.3.6 (Buoc 9, 10, 12)
RUN curl -fsSL "https://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz" \
    | tar -xz -C /usr/local/ \
    && mv /usr/local/hadoop-${HADOOP_VERSION} ${HADOOP_HOME} \
    && mkdir -p ${HADOOP_HOME}/data/nameNode ${HADOOP_HOME}/data/dataNode ${HADOOP_HOME}/logs \
    && echo "export JAVA_HOME=${JAVA_HOME}" >> ${HADOOP_HOME}/etc/hadoop/hadoop-env.sh

# Tai va cai dat Spark 3.5.3 (Phan 3 - Buoc 1, 2)
RUN curl -fsSL "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz" \
    | tar -xz -C /home/hadoopuser/ \
    && mv /home/hadoopuser/spark-${SPARK_VERSION}-bin-hadoop3 ${SPARK_HOME}

# Copy cau hinh Hadoop & YARN (Buoc 22, 29)
COPY config/core-site.xml ${HADOOP_HOME}/etc/hadoop/core-site.xml
COPY config/hdfs-site.xml ${HADOOP_HOME}/etc/hadoop/hdfs-site.xml
COPY config/yarn-site.xml ${HADOOP_HOME}/etc/hadoop/yarn-site.xml
COPY config/workers ${HADOOP_HOME}/etc/hadoop/workers

# Copy demo WordCount (Phan 4 - Buoc 1)
COPY app/input.txt ${SPARK_HOME}/input.txt
COPY app/wordCount.py /home/hadoopuser/wordCount.py

# Cau hinh bien moi truong trong ~/.bashrc cua hadoopuser (Buoc 28 & Phan 3 Buoc 3-5)
RUN printf '\nexport JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64\nexport HADOOP_HOME=/usr/local/hadoop\nexport HADOOP_COMMON_HOME=$HADOOP_HOME\nexport HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop\nexport HADOOP_HDFS_HOME=$HADOOP_HOME\nexport HADOOP_MAPRED_HOME=$HADOOP_HOME\nexport HADOOP_YARN_HOME=$HADOOP_HOME\nexport SPARK_HOME=/home/hadoopuser/spark-3.5.3\nexport PYSPARK_PYTHON=python3\nexport PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin\n' >> /home/hadoopuser/.bashrc \
    && chown -R hadoopuser:hadoopuser ${HADOOP_HOME} /home/hadoopuser

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
