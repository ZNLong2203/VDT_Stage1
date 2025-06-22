package com.vdt.demo;

import com.github.javafaker.Faker;

import java.sql.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

public class DataGenerator {
    
    private static final String DB_URL = "jdbc:postgresql://localhost:5432/ecommerce";
    private static final String DB_USER = "postgres";
    private static final String DB_PASSWORD = "postgres";
    
    private static final Faker faker = new Faker();
    private static final Random random = new Random();
    private static final DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    
    private static final int ORDERS_PER_MINUTE = 120;     
    private static final int ITEMS_PER_ORDER = 3;         
    private static final int NEW_CUSTOMERS_PER_HOUR = 60; 
    private static final int NEW_PRODUCTS_PER_HOUR = 30;  
    private static final int REVIEWS_PER_HOUR = 180;      
    
    private static List<String> existingCustomers = new ArrayList<>();
    private static List<String> existingProducts = new ArrayList<>();
    private static List<String> recentOrders = new ArrayList<>();
    
    // Latency testing configuration
    private static final boolean ENABLE_LATENCY_TESTING = true;
    private static final int LATENCY_TEST_INTERVAL_MINUTES = 1; 
    private static final String STARROCKS_URL = "jdbc:mysql://localhost:9030/ecommerce_ods_clean";
    private static final String STARROCKS_USER = "root";
    private static final String STARROCKS_PASSWORD = "";
    
    // Burst mode configuration
    private static final boolean ENABLE_BURST_MODE = true;
    private static final int BURST_ORDERS_COUNT = 50; 
    private static final int BURST_INTERVAL_MINUTES = 5; 

    public static void main(String[] args) {
        System.out.println("Starting Real-Time Data Generator for ODS CDC Pipeline Demo");
        System.out.println("Configuration:");
        System.out.println("   Orders: " + ORDERS_PER_MINUTE + " per minute");
        System.out.println("   Items per order: ~" + ITEMS_PER_ORDER);
        System.out.println("   New customers: " + NEW_CUSTOMERS_PER_HOUR + " per hour");
        System.out.println("   New products: " + NEW_PRODUCTS_PER_HOUR + " per hour");
        System.out.println("   Reviews: " + REVIEWS_PER_HOUR + " per hour");
        if (ENABLE_LATENCY_TESTING) {
            System.out.println("   Latency testing: Every " + LATENCY_TEST_INTERVAL_MINUTES + " minutes");
        }
        if (ENABLE_BURST_MODE) {
            System.out.println("   Burst mode: " + BURST_ORDERS_COUNT + " orders every " + BURST_INTERVAL_MINUTES + " minutes");
        }
        
        initializeCaches();
        
        // Create scheduler
        ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(6);
        
        scheduleOrderGeneration(scheduler);
        scheduleCustomerGeneration(scheduler);
        scheduleProductGeneration(scheduler);
        scheduleReviewGeneration(scheduler);
        
        if (ENABLE_LATENCY_TESTING) {
            scheduleLatencyTesting(scheduler);
        }
        
        if (ENABLE_BURST_MODE) {
            scheduleBurstMode(scheduler);
        }
        
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            scheduler.shutdown();
        }));
        
        try {
            Thread.currentThread().join();
        } catch (InterruptedException e) {
            System.out.println("Generator interrupted");
        }
    }
    
    private static void initializeCaches() {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD)) {
            try (PreparedStatement stmt = conn.prepareStatement("SELECT customer_id FROM customers LIMIT 1000")) {
                ResultSet rs = stmt.executeQuery();
                while (rs.next()) {
                    existingCustomers.add(rs.getString("customer_id"));
                }
            }
            
            try (PreparedStatement stmt = conn.prepareStatement("SELECT product_id FROM products LIMIT 1000")) {
                ResultSet rs = stmt.executeQuery();
                while (rs.next()) {
                    existingProducts.add(rs.getString("product_id"));
                }
            }
            
            System.out.println("Initialized caches: " + existingCustomers.size() + " customers, " + existingProducts.size() + " products");
        } catch (SQLException e) {
            System.err.println("Error initializing caches: " + e.getMessage());
        }
    }
    
    private static void scheduleOrderGeneration(ScheduledExecutorService scheduler) {
        int batchSize = Math.max(1, ORDERS_PER_MINUTE / 20); 
        int intervalSeconds = 3;
        
        scheduler.scheduleAtFixedRate(() -> {
            try {
                for (int i = 0; i < batchSize; i++) {
                    generateOrder();
                    if (i < batchSize - 1) {
                        Thread.sleep(100);
                    }
                }
            } catch (Exception e) {
                System.err.println("Error generating order batch: " + e.getMessage());
            }
        }, 0, intervalSeconds, TimeUnit.SECONDS);
    }
    
    private static void scheduleCustomerGeneration(ScheduledExecutorService scheduler) {
        int intervalSeconds = 3600 / NEW_CUSTOMERS_PER_HOUR; 
        
        scheduler.scheduleAtFixedRate(() -> {
            try {
                generateCustomer();
            } catch (Exception e) {
                System.err.println("Error generating customer: " + e.getMessage());
            }
        }, 5, intervalSeconds, TimeUnit.SECONDS);
    }
    
    private static void scheduleProductGeneration(ScheduledExecutorService scheduler) {
        int intervalSeconds = 3600 / NEW_PRODUCTS_PER_HOUR;
        
        scheduler.scheduleAtFixedRate(() -> {
            try {
                generateProduct();
            } catch (Exception e) {
                System.err.println("Error generating product: " + e.getMessage());
            }
        }, 10, intervalSeconds, TimeUnit.SECONDS);
    }
    
    private static void scheduleReviewGeneration(ScheduledExecutorService scheduler) {
        int intervalSeconds = 3600 / REVIEWS_PER_HOUR;
        
        scheduler.scheduleAtFixedRate(() -> {
            try {
                generateReview();
            } catch (Exception e) {
                System.err.println("Error generating review: " + e.getMessage());
            }
        }, 15, intervalSeconds, TimeUnit.SECONDS);
    }
    
    private static void generateOrder() throws SQLException {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD)) {
            conn.setAutoCommit(false);
            
            String orderId = "order_" + System.currentTimeMillis() + "_" + random.nextInt(1000);
            String customerId = getRandomCustomerId();
            String[] statuses = {"pending", "processing", "shipped", "delivered", "cancelled"};
            String status = statuses[random.nextInt(statuses.length)];
            LocalDateTime now = LocalDateTime.now();
            LocalDateTime deliveryDate = now.plusDays(3 + random.nextInt(7));
            
            String orderSql = "INSERT INTO orders (order_id, customer_id, order_status, " +
                            "order_purchase_timestamp, order_estimated_delivery_date) VALUES (?, ?, ?, ?, ?)";
            try (PreparedStatement stmt = conn.prepareStatement(orderSql)) {
                stmt.setString(1, orderId);
                stmt.setString(2, customerId);
                stmt.setString(3, status);
                stmt.setTimestamp(4, Timestamp.valueOf(now));
                stmt.setTimestamp(5, Timestamp.valueOf(deliveryDate));
                stmt.executeUpdate();
            }
            
            int numItems = 1 + random.nextInt(ITEMS_PER_ORDER * 2); 
            double totalOrderValue = 0;
            
            for (int i = 0; i < numItems; i++) {
                String productId = getRandomProductId();
                double price = 10 + (random.nextDouble() * 500); 
                double freight = 5 + (random.nextDouble() * 50);  
                totalOrderValue += price + freight;
                
                String itemSql = "INSERT INTO order_items (order_id, product_id, price, freight_value) " +
                               "VALUES (?, ?, ?, ?)";
                try (PreparedStatement stmt = conn.prepareStatement(itemSql)) {
                    stmt.setString(1, orderId);
                    stmt.setString(2, productId);
                    stmt.setDouble(3, Math.round(price * 100.0) / 100.0);
                    stmt.setDouble(4, Math.round(freight * 100.0) / 100.0);
                    stmt.executeUpdate();
                }
            }
            
            String[] paymentTypes = {"credit_card", "debit_card", "boleto", "voucher"};
            String paymentType = paymentTypes[random.nextInt(paymentTypes.length)];
            
            String paymentSql = "INSERT INTO payments (order_id, payment_type, payment_value) VALUES (?, ?, ?)";
            try (PreparedStatement stmt = conn.prepareStatement(paymentSql)) {
                stmt.setString(1, orderId);
                stmt.setString(2, paymentType);
                stmt.setDouble(3, Math.round(totalOrderValue * 100.0) / 100.0);
                stmt.executeUpdate();
            }
            
            conn.commit();
            recentOrders.add(orderId);
            if (recentOrders.size() > 1000) {
                recentOrders.remove(0); 
            }
            
            System.out.println("Generated ORDER: " + orderId + " ($" + 
                             String.format("%.2f", totalOrderValue) + ", " + numItems + " items, " + status + ")");
            
        } catch (SQLException e) {
            System.err.println("Error in generateOrder: " + e.getMessage());
            throw e;
        }
    }
    
    private static void generateCustomer() throws SQLException {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD)) {
            String customerId = "customer_" + System.currentTimeMillis();
            String uniqueId = faker.idNumber().valid();
            String city = faker.address().city();
            String[] states = {"SP", "RJ", "MG", "RS", "PR", "SC", "BA", "GO", "PE", "CE"};
            String state = states[random.nextInt(states.length)];
            
            String sql = "INSERT INTO customers (customer_id, customer_unique_id, customer_city, customer_state) " +
                        "VALUES (?, ?, ?, ?)";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, customerId);
                stmt.setString(2, uniqueId);
                stmt.setString(3, city);
                stmt.setString(4, state);
                stmt.executeUpdate();
            }
            
            existingCustomers.add(customerId);
            System.out.println("Generated CUSTOMER: " + customerId + " from " + city + ", " + state);
        }
    }
    
    private static void generateProduct() throws SQLException {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD)) {
            String productId = "product_" + System.currentTimeMillis();
            String[] categories = {
                "informatica_acessorios", "telefonia", "eletronicos", "casa_construcao",
                "esporte_lazer", "moveis_decoracao", "beleza_saude", "automotivo",
                "moda_bolsas_e_calcados", "cool_stuff", "malas_e_acessorios"
            };
            String category = categories[random.nextInt(categories.length)];
            
            String sql = "INSERT INTO products (product_id, product_category_name) VALUES (?, ?)";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, productId);
                stmt.setString(2, category);
                stmt.executeUpdate();
            }
            
            existingProducts.add(productId);
            System.out.println("Generated PRODUCT: " + productId + " (" + category + ")");
        }
    }
    
    private static void generateReview() throws SQLException {
        if (recentOrders.isEmpty()) return;
        
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD)) {
            String orderId = recentOrders.get(random.nextInt(recentOrders.size()));
            int score = 1 + random.nextInt(5); 

            String sql = "INSERT INTO reviews (order_id, review_score) VALUES (?, ?) " +
                        "ON CONFLICT (order_id) DO NOTHING";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, orderId);
                stmt.setInt(2, score);
                int rowsAffected = stmt.executeUpdate();
                
                if (rowsAffected > 0) {
                    System.out.println("Generated REVIEW: " + orderId + " (" + score + " stars)");
                }
            }
        }
    }
    
    private static String getRandomCustomerId() {
        if (existingCustomers.isEmpty() || random.nextDouble() < 0.1) {
            return random.nextBoolean() ? null : "invalid_customer_" + random.nextInt(1000);
        }
        return existingCustomers.get(random.nextInt(existingCustomers.size()));
    }
    
    private static String getRandomProductId() {
        if (existingProducts.isEmpty() || random.nextDouble() < 0.05) {
            return random.nextBoolean() ? null : "invalid_product_" + random.nextInt(1000);
        }
        return existingProducts.get(random.nextInt(existingProducts.size()));
    }
    
    private static void scheduleLatencyTesting(ScheduledExecutorService scheduler) {
        scheduler.scheduleAtFixedRate(() -> {
            try {
                performLatencyTest();
            } catch (Exception e) {
                System.err.println("Error in latency test: " + e.getMessage());
            }
        }, 30, LATENCY_TEST_INTERVAL_MINUTES * 60, TimeUnit.SECONDS); 
    }
    
    private static void performLatencyTest() {
        System.out.println("\n=== LATENCY TEST STARTING ===");
        
        String testOrderId = "latency_test_" + System.currentTimeMillis();
        String testCustomerId = getRandomCustomerId();
        String testProductId = getRandomProductId();
        
        long startTime = System.currentTimeMillis();
        
        try {
            insertTestOrder(testOrderId, testCustomerId, testProductId);
            
            long latency = waitForDataInStarRocks(testOrderId, startTime);
            
            if (latency > 0) {
                System.out.println("LATENCY TEST RESULT: " + latency + "ms");
                printLatencyAssessment(latency);
            } else {
                System.out.println("LATENCY TEST FAILED: Data not found in StarRocks within timeout");
            }
            
        } catch (Exception e) {
            System.err.println("LATENCY TEST ERROR: " + e.getMessage());
        }
        
        System.out.println("=== LATENCY TEST COMPLETED ===\n");
    }
    
    private static void insertTestOrder(String orderId, String customerId, String productId) throws SQLException {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD)) {
            conn.setAutoCommit(false);
            
            LocalDateTime now = LocalDateTime.now();
            
            String orderSql = "INSERT INTO orders (order_id, customer_id, order_status, order_purchase_timestamp) VALUES (?, ?, ?, ?)";
            try (PreparedStatement stmt = conn.prepareStatement(orderSql)) {
                stmt.setString(1, orderId);
                stmt.setString(2, customerId);
                stmt.setString(3, "pending");
                stmt.setTimestamp(4, Timestamp.valueOf(now));
                stmt.executeUpdate();
            }
            
            String itemSql = "INSERT INTO order_items (order_id, product_id, price, freight_value) VALUES (?, ?, ?, ?)";
            try (PreparedStatement stmt = conn.prepareStatement(itemSql)) {
                stmt.setString(1, orderId);
                stmt.setString(2, productId);
                stmt.setDouble(3, 99.99);
                stmt.setDouble(4, 9.99);
                stmt.executeUpdate();
            }
            
            String paymentSql = "INSERT INTO payments (order_id, payment_type, payment_value) VALUES (?, ?, ?)";
            try (PreparedStatement stmt = conn.prepareStatement(paymentSql)) {
                stmt.setString(1, orderId);
                stmt.setString(2, "credit_card");
                stmt.setDouble(3, 109.98);
                stmt.executeUpdate();
            }
            
            conn.commit();
            System.out.println("Inserted test order: " + orderId);
        }
    }
    
    private static long waitForDataInStarRocks(String orderId, long startTime) {
        int maxAttempts = 60; 
        int attemptInterval = 1000; 
        
        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            try {
                Thread.sleep(attemptInterval);
                
                if (checkOrderInStarRocks(orderId)) {
                    long latency = System.currentTimeMillis() - startTime;
                    System.out.println("Data found in StarRocks after " + attempt + " seconds");
                    return latency;
                }
                
                if (attempt % 10 == 0) {
                    System.out.println("Still waiting... (" + attempt + "s)");
                }
                
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            } catch (Exception e) {
                System.err.println("Error checking StarRocks: " + e.getMessage());
            }
        }
        
        return -1; 
    }
    
    private static boolean checkOrderInStarRocks(String orderId) {
        try (Connection conn = DriverManager.getConnection(STARROCKS_URL, STARROCKS_USER, STARROCKS_PASSWORD)) {
            String sql = "SELECT COUNT(*) FROM ods_orders WHERE order_id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, orderId);
                ResultSet rs = stmt.executeQuery();
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        } catch (SQLException e) {
            System.err.println("Error checking StarRocks: " + e.getMessage());
        }
        return false;
    }
    
    private static void printLatencyAssessment(long latencyMs) {
        double latencySeconds = latencyMs / 1000.0;
        
        System.out.println("Pipeline Performance Assessment:");
        if (latencySeconds < 1) {
            System.out.println("  Status: EXCELLENT (< 1s)");
        } else if (latencySeconds < 5) {
            System.out.println("  Status: GOOD (1-5s)");
        } else if (latencySeconds < 15) {
            System.out.println("  Status: ACCEPTABLE (5-15s)");
        } else if (latencySeconds < 30) {
            System.out.println("  Status: SLOW (15-30s)");
        } else {
            System.out.println("  Status: VERY SLOW (> 30s)");
        }
        
        System.out.println("  Latency: " + String.format("%.2f", latencySeconds) + " seconds");
        System.out.println("  Throughput: ~" + Math.round(1000.0 / latencyMs * 3600) + " records/hour");
    }
    
    private static void scheduleBurstMode(ScheduledExecutorService scheduler) {
        scheduler.scheduleAtFixedRate(() -> {
            try {
                performBurstGeneration();
            } catch (Exception e) {
                System.err.println("Error in burst mode: " + e.getMessage());
            }
        }, 60, BURST_INTERVAL_MINUTES * 60, TimeUnit.SECONDS); 
    }
    
    private static void performBurstGeneration() {
        System.out.println("\n=== BURST MODE STARTING ===");
        System.out.println("Generating " + BURST_ORDERS_COUNT + " orders rapidly...");
        
        long startTime = System.currentTimeMillis();
        int successCount = 0;
        
        for (int i = 0; i < BURST_ORDERS_COUNT; i++) {
            try {
                generateOrder();
                successCount++;
                
                if (i % 10 == 0 && i > 0) {
                    Thread.sleep(50);
                }
                
            } catch (Exception e) {
                System.err.println("Error in burst order " + (i+1) + ": " + e.getMessage());
            }
        }
        
        long duration = System.currentTimeMillis() - startTime;
        double ordersPerSecond = successCount / (duration / 1000.0);
        
        System.out.println("BURST COMPLETED:");
        System.out.println("  Generated: " + successCount + "/" + BURST_ORDERS_COUNT + " orders");
        System.out.println("  Duration: " + String.format("%.2f", duration/1000.0) + " seconds");
        System.out.println("  Rate: " + String.format("%.1f", ordersPerSecond) + " orders/second");
        System.out.println("=== BURST MODE COMPLETED ===\n");
    }
} 