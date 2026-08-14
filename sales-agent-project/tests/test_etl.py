import pandas as pd
from pyspark.sql import SparkSession
from src.etl.build_sales_table import transform

def test_transform_aggregates_revenue():
    spark = SparkSession.builder.master("local[1]").getOrCreate()
    pdf = pd.DataFrame(
        {
            "order_id": [1, 2],
            "region": ["APAC", "APAC"],
            "category": ["Electronics", "Electronics"],
            "product": ["Mouse", "Mouse"],
            "quantity": [2, 3],
            "unit_price": [10000, 10000]
        }
    )
    sdf = spark.createDataFrame(pdf)
    result = transform(sdf).collect()[0]
    
    assert result["total_qty"] == 5
    assert result["total_revenue"] == 50000