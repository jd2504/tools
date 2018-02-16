from pyspark.sql import SparkSession
from pyspark.sql import HiveContext
from pyspark.sql.window import Window
import pyspark.sql.functions as F
from pyspark.sql.types import StringType

ss = SparkSession.builder.appName("ada_ds_cnn_web_engagement_by_dropoff").enableHiveSupport().getOrCreate()
hc = HiveContext(ss)

#---------------------------------------------------------------------------------------------------------------------------------------------------
first_month = "'2017-01-%'"
second_month = "'2017-02-%'"
non_dropouts_table = "temp_user_store.rt_nondropouts_jan2017"
dropouts_table = "temp_user_store.rt_dropouts_jan2017"

def rename_device(device):
  if device in ('games console', 'tv', 'set top box', 'desktop', ''):
    return 'desktop'
  elif device in ('mobile phone', 'media player', 'tablet', 'ereader'):
    return 'mobile'
  else:
    return 'other'
rename_device = F.udf(rename_device, StringType())

#---------------------------------------------------------------------------------------------------------------------------------------------------
# Extract individual events
events = hc.sql("SELECT  \
                        visitor_id, \
                        hit_time_gmt, \
                        file_date, \
                        month(file_date) as month, \
                        session_id, \
                        pageview_event_cnt, \
                        video_start_cnt, \
                        video_time_spent_secs, \
                        browser_typ_dsc, \
                        device_type_dsc as device \
                FROM user_business_defined_dataset.cnn_adobe_bdd_web \
                WHERE file_date like %s \
                AND (visitor_id != '*UN' OR visitor_id != '-100')" % first_month)
events = events.dropDuplicates(["visitor_id","hit_time_gmt"])
events = events.fillna('desktop', subset=['device'])
events = events.withColumn('device', rename_device(F.col("device")))
events = events.filter(F.col('device')!='other')
window = Window.orderBy(F.col("hit_time_gmt").desc()).partitionBy(["visitor_id", "session_id"])
events = events.withColumn("time_on_event", (F.lag(events.hit_time_gmt, 1).over(window) - events.hit_time_gmt))
events = events.fillna(0.0, subset=['time_on_event'])

#---------------------------------------------------------------------------------------------------------------------------------------------------
# Get traffic features
visitors_1 = events.groupby(["visitor_id","device"]).agg(F.countDistinct("session_id").alias("visits"),
                                                          F.sum("pageview_event_cnt").alias("pageviews"),
                                                          F.sum("video_start_cnt").alias("videostarts"),
                                                          F.sum("time_on_event").alias("time_on_site"), 
                                                          F.sum("video_time_spent_secs").alias("video_playtime"),
                                                          F.first("browser_typ_dsc").alias("browser_typ_dsc"),
                                                          F.countDistinct("file_date").alias("days_visited")).fillna(0.0)

#---------------------------------------------------------------------------------------------------------------------------------------------------
# Split visitors by monthly dropouts vs non-dropouts
visitors_2 = hc.sql("SELECT distinct visitor_id \
                        FROM user_business_defined_dataset.cnn_adobe_bdd_web \
                        WHERE file_date like %s AND (visitor_id != '*UN' AND visitor_id != '-100')" % second_month)
non_dropouts = visitors_2.join(visitors_1, "visitor_id")
non_dropouts.write.saveAsTable(non_dropouts_table, mode="overwrite")

dropouts = visitors_1.select('visitor_id').subtract(non_dropouts.select('visitor_id'))
dropouts = visitors_1.join(dropouts,'visitor_id')
dropouts.write.saveAsTable(dropouts_table, mode="overwrite")
