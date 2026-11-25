# Tuần 3: Dựng mô hình Cluster 1 Master – 2 Slaves (Hadoop – YARN – Spark trên Ubuntu)

Thư mục này triển khai **đúng y hệt mô hình 3 máy Ubuntu** trong đề Tuần 3 (`hadoop-master`, `hadoop-slave1`, `hadoop-slave2`, user `hadoopuser`, SSH không mật khẩu, Hadoop 3.3.6, HDFS `dfs.replication = 2`, YARN, Spark 3.5.3, Demo WordCount).

---

## 6 lỗi trong đề gốc đã được sửa sẵn (rất quan trọng nếu bạn tự gõ trên VMware/VirtualBox!)

| Vị trí trong đề gốc | Lỗi trong đề gốc | Cách sửa đúng |
|---|---|---|
| **Bước 9** (tải Hadoop) | Link viết hoa `Hadoop-3.3.6` (bị 404) | Viết thường: `https://archive.apache.org/dist/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz` |
| **Bước 24** (format HDFS) | `hdfs namenode –format` (dấu gạch dài `–` từ Word) | Dùng dấu trừ thường: `hdfs namenode -format` |
| **Phần 3 - Bước 1** (tải Spark) | `spark-3.5.3-bin-hadoop3.2.tgz` (không tồn tại) | `https://archive.apache.org/dist/spark/spark-3.5.3/spark-3.5.3-bin-hadoop3.tgz` |
| **Phần 3 - Bước 3–5** (`JAVA_HOME`) | Đề cài `openjdk-11-jdk` nhưng ghi `java-8-openjdk-amd64` | Sửa thành: `export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64` |
| **Phần 3 - Bước 6** (cài Python) | `sudo apt-get install python` (lỗi trên Ubuntu 22.04+) | `sudo apt-get install -y python3 python-is-python3` |
| **Phần 4 - Bước 3** (Web UI Spark) | Ghi nhầm cổng `8088` (đây là cổng của **YARN**) | **YARN UI:** `:8088/cluster` — **Spark Master UI:** `:8080` — **HDFS UI:** `:9870` |

---

## Cách 1: Chạy nhanh KHÔNG CẦN CÀI 3 máy ảo (dùng GitHub Codespaces hoặc Docker)

Thay vì tạo 3 máy ảo VMware/VirtualBox nặng ~12 GB RAM, `docker-compose.yml` sẽ dựng **3 container Ubuntu 22.04 thật** (`hadoop-master`, `hadoop-slave1`, `hadoop-slave2`) có sẵn SSH, `hadoopuser`, Hadoop 3.3.6 và Spark 3.5.3.

```bash
cd tuan3-ubuntu-cluster
bash scripts/run_tuan3.sh
```

Sau khi chạy xong, mở trình duyệt (hoặc tab **Ports** trong GitHub Codespaces) để chụp ảnh báo cáo:
- **HDFS NameNode UI:** `http://localhost:9870` → thấy **2 Live Datanodes** (`hadoop-slave1`, `hadoop-slave2`)
- **YARN ResourceManager UI:** `http://localhost:8088/cluster` → thấy **2 Active Nodes**
- **Spark Master UI:** `http://localhost:8080` → thấy **2 Alive Workers** và ứng dụng **Tuan3-WordCount** trong mục *Completed Applications*
- **Spark Worker 1 & 2 UI:** `http://localhost:8081` và `http://localhost:8082`

### Muốn vào trực tiếp terminal của từng máy để thao tác tay giống hệt đề bài:
```bash
# Vào máy master với user hadoopuser
docker exec -it -u hadoopuser hadoop-master bash

# Thử SSH từ master sang slave1, slave2 (không cần mật khẩu)
ssh hadoop-slave1
exit
ssh hadoop-slave2
exit
```

---

## Cách 2: Nếu bạn bắt buộc làm trên 3 máy ảo Ubuntu thật (VMware / VirtualBox)

1. Tạo 1 máy ảo Ubuntu 22.04 (`hadoop-master`), cài SSH, Java 11 (`openjdk-11-jdk`), Python 3 (`python3 python-is-python3`), tải & giải nén Hadoop 3.3.6 vào `/usr/local/hadoop`, tạo user `hadoopuser`, tải & giải nén Spark 3.5.3 vào `/home/hadoopuser/spark-3.5.3`.
2. **Clone** máy `hadoop-master` thành 2 máy `hadoop-slave1` và `hadoop-slave2` (Bước 17).
3. Kiểm tra IP 3 máy bằng `ip addr`, cập nhật `/etc/hosts` trên cả 3 máy:
   ```text
   192.168.x.x1  hadoop-master
   192.168.x.x2  hadoop-slave1
   192.168.x.x3  hadoop-slave2
   ```
4. Đổi tên máy trong `/etc/hostname` (`hadoop-master`, `hadoop-slave1`, `hadoop-slave2`) rồi `sudo reboot`.
5. Trên `hadoop-master` (user `hadoopuser`), tạo SSH key và copy sang 3 máy (`ssh-copy-id hadoopuser@hadoop-master`, `hadoop-slave1`, `hadoop-slave2`).
6. Copy 4 file cấu hình từ thư mục `config/` (`core-site.xml`, `hdfs-site.xml`, `yarn-site.xml`, `workers`) vào `/usr/local/hadoop/etc/hadoop/`, rồi `scp` sang `hadoop-slave1` và `hadoop-slave2`.
7. Format & khởi chạy HDFS + YARN trên `hadoop-master`:
   ```bash
   hdfs namenode -format
   start-dfs.sh
   start-yarn.sh
   ```
8. Copy `app/input.txt` vào `/home/hadoopuser/spark-3.5.3/input.txt` và `app/wordCount.py` vào `/home/hadoopuser/wordCount.py` (nhớ copy `input.txt` sang cả 2 máy slave ở cùng đường dẫn, hoặc đẩy lên HDFS!).
9. Chạy Spark Master trên `hadoop-master`:
   ```bash
   cd ~/spark-3.5.3
   bin/spark-class org.apache.spark.deploy.master.Master
   ```
10. Chạy Spark Worker trên `hadoop-slave1` và `hadoop-slave2`:
    ```bash
    cd ~/spark-3.5.3
    bin/spark-class org.apache.spark.deploy.worker.Worker spark://hadoop-master:7077
    ```
11. Chạy `wordCount.py` trên `hadoop-master`:
    ```bash
    cd ~/spark-3.5.3
    bin/spark-submit --master spark://hadoop-master:7077 /home/hadoopuser/wordCount.py /home/hadoopuser/spark-3.5.3/input.txt
    ```
