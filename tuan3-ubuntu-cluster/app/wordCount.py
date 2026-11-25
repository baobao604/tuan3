import sys
from pyspark.sql import SparkSession


def main():
    if len(sys.argv) < 2:
        print("Usage: wordCount.py <input_file>")
        sys.exit(1)

    input_path = sys.argv[1]
    spark = SparkSession.builder.appName("Tuan3-WordCount").getOrCreate()

    rdd = spark.sparkContext.textFile(input_path)
    counts = (
        rdd.flatMap(lambda line: line.split())
        .map(lambda w: (w.lower(), 1))
        .reduceByKey(lambda a, b: a + b)
        .sortBy(lambda x: -x[1])
    )

    print("=== KET QUA WORDCOUNT ===")
    for word, count in counts.collect():
        print(f"{word}: {count}")

    spark.stop()


if __name__ == "__main__":
    main()
