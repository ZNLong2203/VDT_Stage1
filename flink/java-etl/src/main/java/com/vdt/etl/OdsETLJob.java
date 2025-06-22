package com.vdt.etl;

import org.apache.flink.streaming.api.environment.StreamExecutionEnvironment;
import org.apache.flink.table.api.EnvironmentSettings;
import org.apache.flink.table.api.bridge.java.StreamTableEnvironment;

public class OdsETLJob {

    public static void main(String[] args) throws Exception {
        StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();

        env.setParallelism(4); 
        env.enableCheckpointing(30000); 
        
        StreamTableEnvironment tableEnv = StreamTableEnvironment.create(
            env, EnvironmentSettings.newInstance().inStreamingMode().build()
        );
                
        createSourceTables(tableEnv);
        
        createSinkTables(tableEnv);
        
        OrderProcessor.processOrdersWithSQL(tableEnv);
        OrderItemProcessor.processOrderItemsWithSQL(tableEnv);
        ProductProcessor.processProductsWithSQL(tableEnv);
        ReviewProcessor.processReviewsWithSQL(tableEnv);
        PaymentProcessor.processPaymentsWithSQL(tableEnv);
        CustomerProcessor.processCustomersWithSQL(tableEnv);
        
        System.out.println("All ETL jobs submitted successfully!");
    }
    
    private static void createSourceTables(StreamTableEnvironment tableEnv) {        
        tableEnv.executeSql(SqlQueries.CREATE_ORDERS_SOURCE);
        tableEnv.executeSql(SqlQueries.CREATE_ORDER_ITEMS_SOURCE);
        tableEnv.executeSql(SqlQueries.CREATE_PRODUCTS_SOURCE);
        tableEnv.executeSql(SqlQueries.CREATE_REVIEWS_SOURCE);
        tableEnv.executeSql(SqlQueries.CREATE_PAYMENTS_SOURCE);
        tableEnv.executeSql(SqlQueries.CREATE_CUSTOMERS_SOURCE);
        
        System.out.println("Source tables created");
    }
    
    private static void createSinkTables(StreamTableEnvironment tableEnv) {        
        // Clean data sinks
        tableEnv.executeSql(SqlQueries.CREATE_ORDERS_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_ORDER_ITEMS_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_PRODUCTS_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_REVIEWS_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_PAYMENTS_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_CUSTOMERS_SINK);
        
        // Error data sinks
        tableEnv.executeSql(SqlQueries.CREATE_ORDERS_ERROR_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_ORDER_ITEMS_ERROR_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_PRODUCTS_ERROR_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_REVIEWS_ERROR_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_PAYMENTS_ERROR_SINK);
        tableEnv.executeSql(SqlQueries.CREATE_CUSTOMERS_ERROR_SINK);
        
        System.out.println("Sink tables created");
    }
} 