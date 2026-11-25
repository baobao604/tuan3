$ErrorActionPreference = "Stop"

Set-Location (Join-Path $PSScriptRoot "..")

Write-Host "=== 1. Kiem tra Docker ===" -ForegroundColor Cyan
docker --version
docker info | Out-Null

Write-Host "`n=== 2. Build va khoi dong 3 may Ubuntu (hadoop-master, hadoop-slave1, hadoop-slave2) ===" -ForegroundColor Cyan
docker compose up -d --build
Start-Sleep -Seconds 5
docker compose ps

Write-Host "`n=== 3. Kiem tra SSH khong mat khau tu hadoop-master sang slave1 & slave2 ===" -ForegroundColor Cyan
docker exec -u hadoopuser hadoop-master ssh hadoop-slave1 hostname
docker exec -u hadoopuser hadoop-master ssh hadoop-slave2 hostname

Write-Host "`n=== 4. Dinh dang NameNode va khoi dong HDFS (start-dfs.sh) ===" -ForegroundColor Cyan
docker exec -u hadoopuser hadoop-master bash -lc "if [ ! -f /usr/local/hadoop/data/nameNode/current/VERSION ]; then hdfs namenode -format -force; fi; start-dfs.sh"
Start-Sleep -Seconds 5
docker exec -u hadoopuser hadoop-master bash -lc "hdfs dfsadmin -report | head -n 25"

Write-Host "`n=== 5. Khoi dong YARN (start-yarn.sh) va kiem tra NodeManager ===" -ForegroundColor Cyan
docker exec -u hadoopuser hadoop-master bash -lc "start-yarn.sh"
Start-Sleep -Seconds 5
docker exec -u hadoopuser hadoop-master bash -lc "yarn node -list"

Write-Host "`n=== 6. Khoi dong Spark Master & 2 Spark Workers ===" -ForegroundColor Cyan
docker exec -u hadoopuser -d hadoop-master bash -lc "/home/hadoopuser/spark-3.5.3/sbin/start-master.sh"
Start-Sleep -Seconds 4
docker exec -u hadoopuser -d hadoop-slave1 bash -lc "/home/hadoopuser/spark-3.5.3/sbin/start-worker.sh spark://hadoop-master:7077"
docker exec -u hadoopuser -d hadoop-slave2 bash -lc "/home/hadoopuser/spark-3.5.3/sbin/start-worker.sh spark://hadoop-master:7077"
Start-Sleep -Seconds 5

Write-Host "`n=== 7. Chay Demo WordCount tren cum Spark (Phan 4 - Buoc 10) ===" -ForegroundColor Cyan
docker exec -u hadoopuser hadoop-master bash -lc "/home/hadoopuser/spark-3.5.3/bin/spark-submit --master spark://hadoop-master:7077 /home/hadoopuser/wordCount.py /home/hadoopuser/spark-3.5.3/input.txt"

Write-Host "`n=== HOAN TAT TUAN 3! Mo cac link sau tren trinh duyet: ===" -ForegroundColor Green
Write-Host "  - HDFS NameNode UI:        http://localhost:9870"
Write-Host "  - YARN ResourceManager UI: http://localhost:8088/cluster"
Write-Host "  - Spark Master UI:         http://localhost:8080"
Write-Host "  - Spark Worker 1 UI:       http://localhost:8081"
Write-Host "  - Spark Worker 2 UI:       http://localhost:8082"
