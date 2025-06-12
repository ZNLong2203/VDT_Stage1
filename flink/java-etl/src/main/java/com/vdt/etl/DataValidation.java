package com.vdt.etl;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;

/**
 * Java-based Data Validation Rules
 * This approach is more flexible and easier to understand for freshers
 */
public class DataValidation {
    
    // Validation result class
    public static class ValidationResult {
        private boolean isValid;
        private List<String> errors;
        
        public ValidationResult() {
            this.isValid = true;
            this.errors = new ArrayList<>();
        }
        
        public void addError(String error) {
            this.isValid = false;
            this.errors.add(error);
        }
        
        public boolean isValid() { return isValid; }
        public List<String> getErrors() { return errors; }
        public String getErrorMessage() { return String.join("; ", errors); }
    }
    
    /**
     * Validate Orders data
     */
    public static ValidationResult validateOrder(
            String orderId, 
            String customerId, 
            String orderStatus, 
            String orderTimestamp) {
        
        ValidationResult result = new ValidationResult();
        
        // 1. Check required fields
        if (isNullOrEmpty(orderId)) {
            result.addError("Order ID is required");
        }
        if (isNullOrEmpty(customerId)) {
            result.addError("Customer ID is required");
        }
        if (isNullOrEmpty(orderStatus)) {
            result.addError("Order status is required");
        }
        if (isNullOrEmpty(orderTimestamp)) {
            result.addError("Order timestamp is required");
        }
        
        // 2. Check field formats and lengths
        if (!isNullOrEmpty(orderId) && orderId.length() > 50) {
            result.addError("Order ID too long (max 50 characters)");
        }
        
        if (!isNullOrEmpty(customerId) && customerId.length() > 50) {
            result.addError("Customer ID too long (max 50 characters)");
        }
        
        // 3. Check valid order status
        if (!isNullOrEmpty(orderStatus)) {
            List<String> validStatuses = List.of("pending", "processing", "shipped", "delivered", "cancelled");
            if (!validStatuses.contains(orderStatus.toLowerCase())) {
                result.addError("Invalid order status: " + orderStatus);
            }
        }
        
        // 4. Check timestamp format
        if (!isNullOrEmpty(orderTimestamp) && !isValidDateTime(orderTimestamp)) {
            result.addError("Invalid timestamp format: " + orderTimestamp);
        }
        
        return result;
    }
    
    /**
     * Validate Order Items data
     */
    public static ValidationResult validateOrderItem(
            String orderId, 
            String productId, 
            Double price, 
            Double freightValue) {
        
        ValidationResult result = new ValidationResult();
        
        // 1. Check required fields
        if (isNullOrEmpty(orderId)) {
            result.addError("Order ID is required");
        }
        if (isNullOrEmpty(productId)) {
            result.addError("Product ID is required");
        }
        if (price == null) {
            result.addError("Price is required");
        }
        if (freightValue == null) {
            result.addError("Freight value is required");
        }
        
        // 2. Check business rules
        if (price != null && price < 0) {
            result.addError("Price cannot be negative");
        }
        if (price != null && price > 10000) {
            result.addError("Price too high (max $10,000)");
        }
        
        if (freightValue != null && freightValue < 0) {
            result.addError("Freight value cannot be negative");
        }
        
        // 3. Check field lengths
        if (!isNullOrEmpty(orderId) && orderId.length() > 50) {
            result.addError("Order ID too long");
        }
        if (!isNullOrEmpty(productId) && productId.length() > 50) {
            result.addError("Product ID too long");
        }
        
        return result;
    }
    
    /**
     * Validate Products data
     */
    public static ValidationResult validateProduct(
            String productId, 
            String categoryName) {
        
        ValidationResult result = new ValidationResult();
        
        // 1. Check required fields
        if (isNullOrEmpty(productId)) {
            result.addError("Product ID is required");
        }
        if (isNullOrEmpty(categoryName)) {
            result.addError("Category name is required");
        }
        
        // 2. Check field lengths
        if (!isNullOrEmpty(productId) && productId.length() > 50) {
            result.addError("Product ID too long");
        }
        if (!isNullOrEmpty(categoryName) && categoryName.length() > 100) {
            result.addError("Category name too long");
        }
        
        return result;
    }
    
    /**
     * Validate Reviews data
     */
    public static ValidationResult validateReview(
            String orderId, 
            Integer reviewScore) {
        
        ValidationResult result = new ValidationResult();
        
        // 1. Check required fields
        if (isNullOrEmpty(orderId)) {
            result.addError("Order ID is required");
        }
        if (reviewScore == null) {
            result.addError("Review score is required");
        }
        
        // 2. Check business rules
        if (reviewScore != null && (reviewScore < 1 || reviewScore > 5)) {
            result.addError("Review score must be between 1 and 5");
        }
        
        // 3. Check field lengths
        if (!isNullOrEmpty(orderId) && orderId.length() > 50) {
            result.addError("Order ID too long");
        }
        
        return result;
    }
    
    /**
     * Validate Payments data
     */
    public static ValidationResult validatePayment(
            String orderId, 
            String paymentType, 
            Double paymentValue) {
        
        ValidationResult result = new ValidationResult();
        
        // 1. Check required fields
        if (isNullOrEmpty(orderId)) {
            result.addError("Order ID is required");
        }
        if (isNullOrEmpty(paymentType)) {
            result.addError("Payment type is required");
        }
        if (paymentValue == null) {
            result.addError("Payment value is required");
        }
        
        // 2. Check business rules
        if (paymentValue != null && paymentValue <= 0) {
            result.addError("Payment value must be positive");
        }
        if (paymentValue != null && paymentValue > 50000) {
            result.addError("Payment value too high (max $50,000)");
        }
        
        // 3. Check valid payment types
        if (!isNullOrEmpty(paymentType)) {
            List<String> validTypes = List.of("credit_card", "debit_card", "voucher", "boleto");
            if (!validTypes.contains(paymentType.toLowerCase())) {
                result.addError("Invalid payment type: " + paymentType);
            }
        }
        
        return result;
    }
    
    // Helper methods
    private static boolean isNullOrEmpty(String str) {
        return str == null || str.trim().isEmpty();
    }
    
    private static boolean isValidDateTime(String dateTimeStr) {
        try {
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
            LocalDateTime.parse(dateTimeStr, formatter);
            return true;
        } catch (DateTimeParseException e) {
            return false;
        }
    }
} 