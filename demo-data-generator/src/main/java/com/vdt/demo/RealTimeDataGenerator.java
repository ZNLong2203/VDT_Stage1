package com.vdt.demo;

import com.github.javafaker.Faker;

import java.sql.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

public class RealTimeDataGenerator {
    
    private static final String DB_URL = "jdbc:postgresql://localhost:5432/ecommerce";
    private static final String DB_USER = "postgres";
    private static final String DB_PASSWORD = "postgres";
    
    private static final Faker faker = new Faker();
    private static final Random random = new Random();
    private static final DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    
    private static final int ORDERS_PER_MINUTE = 20;      // 20 orders per minute
    private static final int ITEMS_PER_ORDER = 2;         // Average 2 items per order
    private static final int NEW_CUSTOMERS_PER_HOUR = 10; // 10 new customers per hour
    private static final int NEW_PRODUCTS_PER_HOUR = 5;   // 5 new products per hour
    private static final int REVIEWS_PER_HOUR = 30;       // 30 reviews per hour
    
    private static List<String> existingCustomers = new ArrayList<>();
    private static List<String> existingProducts = new ArrayList<>();
    private static List<String> recentOrders = new ArrayList<>();
    
    public static void main(String[] args) {
        System.out.println("Starting Real-Time Data Generator for ODS CDC Pipeline Demo");
        System.out.println("Configuration:");
        System.out.println("   • Orders: " + ORDERS_PER_MINUTE + " per minute");
        System.out.println("   • Items per order: ~" + ITEMS_PER_ORDER);
        System.out.println("   • New customers: " + NEW_CUSTOMERS_PER_HOUR + " per hour");
        System.out.println("   • New products: " + NEW_PRODUCTS_PER_HOUR + " per hour");
        System.out.println("   • Reviews: " + REVIEWS_PER_HOUR + " per hour");
        
        // Initialize caches
        initializeCaches();
        
        // Create scheduler
        ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(6);
        
        // Schedule different data generation tasks
        scheduleOrderGeneration(scheduler);
        scheduleCustomerGeneration(scheduler);
        scheduleProductGeneration(scheduler);
        scheduleReviewGeneration(scheduler);
        
        // Keep the application running
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            scheduler.shutdown();
        }));
        
        // Keep main thread alive
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
        int intervalSeconds = 60 / ORDERS_PER_MINUTE; 
        
        scheduler.scheduleAtFixedRate(() -> {
            try {
                generateOrder();
            } catch (Exception e) {
                System.err.println("Error generating order: " + e.getMessage());
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
            
            int numItems = 1 + random.nextInt(ITEMS_PER_ORDER + 1);
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
                    System.out.println("⭐ Generated REVIEW: " + orderId + " (" + score + " stars)");
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
} 