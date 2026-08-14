"""원본 CSV를 읽어 집계 Delta 테이블을 만드는 ETL 스크립트"""
from pyspark.sql import SparkSession
from pyspark.sql import functions as F

RAW_PATH = "/Volumes/richard_dev/sales_agent/raw_files/sample_sales.csv"
TARGET_TABLE = "richard_dev.sales_agent.sales_summary"

def get_spark() -> SparkSession:
    return SparkSession.builder.getOrCreate()

def load_raw(spark: SparkSession):
    return (
        spark.read.option("header", True)
        .option("inferSchema", True)
        .csv(RAW_PATH)
    )
    
def transform(df):
    df = df.withColumn("revenue", F.col("quantity") * F.col("unit_price"))
    summary = (
        df.groupBy("region", "category", "product")
        .agg(
            F.sum("quantity").alias("total_qty"),
            F.sum("revenue").alias("total_revenue"),
            F.count("order_id").alias("order_count"),
        )
        .orderBy(F.desc("total_revenue"))
    )
    return summary

def main():
    spark = get_spark()
    raw_df = load_raw(spark)
    summary_df = transform(raw_df)
    
    (
        summary_df.write.mode("overwrite")
        .option("overwriteSchema", "true")
        .saveAsTable(TARGET_TABLE)
    )
    print(f"'{TARGET_TABLE}' 테이블 갱신 완료. row count = {summary_df.count()}")
    

if __name__ == "__main__":
    main()