#!/usr/bin/env bash
set -e

echo "=== 1. Build va khoi dong 3 may Ubuntu (hadoop-master, hadoop-slave1, hadoop-slave2) ==="
docker compose up -d --build
sleep 5
docker compose ps

echo ""
echo "=== 2. Kiem tra SSH khong mat khau tu hadoop-master sang slave1 & slave2 ==="
docker exec -u hadoopuser hadoop-master ssh hadoop-slave1 hostname
docker exec -u hadoopuser hadoop-master ssh hadoop-slave2 hostname

echo ""
echo "=== 3. Dinh dang NameNode va khoi dong HDFS (start-dfs.sh) ==="
docker exec -u hadoopuser hadoop-master bash -lc "
  if [ ! -f /usr/local/hadoop/data/nameNode/current/VERSION ]; then
    hdfs namenode -format -force
  fi
  start-dfs.sh
"
sleep 5
docker exec -u hadoopuser hadoop-master bash -lc "hdfs dfsadmin -report | head -n 25"

echo ""
echo "=== 4. Khoi dong YARN (start-yarn.sh) va kiem tra NodeManager ==="
docker exec -u hadoopuser hadoop-master bash -lc "start-yarn.sh"
sleep 5
docker exec -u hadoopuser hadoop-master bash -lc "yarn node -list"

echo ""
echo "=== 5. Khoi dong Spark Master & 2 Spark Workers ==="
docker exec -u hadoopuser -d hadoop-master bash -lc "/home/hadoopuser/spark-3.5.3/sbin/start-master.sh"
sleep 4
docker exec -u hadoopuser -d hadoop-slave1 bash -lc "/home/hadoopuser/spark-3.5.3/sbin/start-worker.sh spark://hadoop-master:7077"
docker exec -u hadoopuser -d hadoop-slave2 bash -lc "/home/hadoopuser/spark-3.5.3/sbin/start-worker.sh spark://hadoop-master:7077"
sleep 5

echo ""
echo "=== 6. Chay Demo WordCount tren cum Spark (Phan 4 - Buoc 10) ==="
docker exec -u hadoopuser hadoop-master bash -lc "
  /home/hadoopuser/spark-3.5.3/bin/spark-submit \
    --master spark://hadoop-master:7077 \
    /home/hadoopuser/wordCount.py \
    /home/hadoopuser/spark-3.5.3/input.txt
"

echo ""
echo "=== HOAN TAT! Mo cac cong Web UI sau de chup anh bao cao: ==="
echo "  - HDFS NameNode UI:        http://localhost:9870  (co 2 Live Datanodes: slave1, slave2)"
echo "  - YARN ResourceManager UI: http://localhost:8088/cluster  (co 2 Active Nodes)"
echo "  - Spark Master UI:         http://localhost:8080  (co 2 Alive Workers)"
echo "  - Spark Worker 1 UI:       http://localhost:8081"
echo "  - Spark Worker 2 UI:       http://localhost:8082"
