package com.vdt.etl;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;

/**
 * Java-based Data Validation Rules with Soft Delete Support
 * This approach is more flexible and easier to understand for freshers
 * Enhanced with soft delete validation and audit fields
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
     * Validate Orders data with soft delete support
     */
    public static ValidationResult validateOrder(
            String orderId, 
            String customerId, 
            String orderStatus, 
            String orderTimestamp,
            Boolean isDeleted) {
        
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
        
        // 5. Validate soft delete flag
        if (isDeleted == null) {
            result.addError("is_deleted flag is required");
        }
        
        return result;
    }
    
    /**
     * Validate Order Items data with soft delete support
     */
    public static ValidationResult validateOrderItem(
            String orderId, 
            String productId, 
            Double price, 
            Double freightValue,
            Boolean isDeleted) {
        
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
        
        // 4. Validate soft delete flag
        if (isDeleted == null) {
            result.addError("is_deleted flag is required");
        }
        
        return result;
    }
    
    /**
     * Validate Products data with soft delete support
     */
    public static ValidationResult validateProduct(
            String productId, 
            String categoryName,
            Boolean isDeleted) {
        
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
        
        // 3. Validate soft delete flag
        if (isDeleted == null) {
            result.addError("is_deleted flag is required");
        }
        
        return result;
    }
    
    /**
     * Validate Reviews data with soft delete support
     */
    public static ValidationResult validateReview(
            String orderId, 
            Integer reviewScore,
            Boolean isDeleted) {
        
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
        
        // 4. Validate soft delete flag
        if (isDeleted == null) {
            result.addError("is_deleted flag is required");
        }
        
        return result;
    }
    
    /**
     * Validate Payments data with soft delete support
     */
    public static ValidationResult validatePayment(
            String orderId, 
            String paymentType, 
            Double paymentValue,
            Boolean isDeleted) {
        
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
        
        // 4. Validate soft delete flag
        if (isDeleted == null) {
            result.addError("is_deleted flag is required");
        }
        
        return result;
    }
    
    /**
     * Validate audit fields (created_at, updated_at)
     */
    public static ValidationResult validateAuditFields(
            String createdAt, 
            String updatedAt) {
        
        ValidationResult result = new ValidationResult();
        
        // 1. Check required fields
        if (isNullOrEmpty(createdAt)) {
            result.addError("created_at is required");
        }
        if (isNullOrEmpty(updatedAt)) {
            result.addError("updated_at is required");
        }
        
        // 2. Check timestamp formats
        if (!isNullOrEmpty(createdAt) && !isValidDateTime(createdAt)) {
            result.addError("Invalid created_at format: " + createdAt);
        }
        if (!isNullOrEmpty(updatedAt) && !isValidDateTime(updatedAt)) {
            result.addError("Invalid updated_at format: " + updatedAt);
        }
        
        // 3. Business rule: updated_at should be >= created_at
        if (!isNullOrEmpty(createdAt) && !isNullOrEmpty(updatedAt)) {
            try {
                DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
                LocalDateTime created = LocalDateTime.parse(createdAt, formatter);
                LocalDateTime updated = LocalDateTime.parse(updatedAt, formatter);
                
                if (updated.isBefore(created)) {
                    result.addError("updated_at cannot be before created_at");
                }
            } catch (DateTimeParseException e) {
                // Already handled in timestamp format validation
            }
        }
        
        return result;
    }
    
    /**
     * Utility method to validate soft delete operation
     */
    public static ValidationResult validateSoftDeleteOperation(
            String recordId, 
            String tableType, 
            Boolean currentDeleteStatus) {
        
        ValidationResult result = new ValidationResult();
        
        // 1. Check required fields
        if (isNullOrEmpty(recordId)) {
            result.addError("Record ID is required for soft delete operation");
        }
        if (isNullOrEmpty(tableType)) {
            result.addError("Table type is required for soft delete operation");
        }
        if (currentDeleteStatus == null) {
            result.addError("Current delete status is required");
        }
        
        // 2. Check valid table types
        if (!isNullOrEmpty(tableType)) {
            List<String> validTables = List.of("orders", "order_items", "products", "reviews", "payments");
            if (!validTables.contains(tableType.toLowerCase())) {
                result.addError("Invalid table type for soft delete: " + tableType);
            }
        }
        
        // 3. Business rule: cannot soft delete already deleted record
        if (currentDeleteStatus != null && currentDeleteStatus) {
            result.addError("Record is already soft deleted");
        }
        
        return result;
    }
    
    /**
     * Utility method to validate restore operation (un-soft delete)
     */
    public static ValidationResult validateRestoreOperation(
            String recordId, 
            String tableType, 
            Boolean currentDeleteStatus) {
        
        ValidationResult result = new ValidationResult();
        
        // 1. Check required fields
        if (isNullOrEmpty(recordId)) {
            result.addError("Record ID is required for restore operation");
        }
        if (isNullOrEmpty(tableType)) {
            result.addError("Table type is required for restore operation");
        }
        if (currentDeleteStatus == null) {
            result.addError("Current delete status is required");
        }
        
        // 2. Check valid table types
        if (!isNullOrEmpty(tableType)) {
            List<String> validTables = List.of("orders", "order_items", "products", "reviews", "payments");
            if (!validTables.contains(tableType.toLowerCase())) {
                result.addError("Invalid table type for restore: " + tableType);
            }
        }
        
        // 3. Business rule: cannot restore non-deleted record
        if (currentDeleteStatus != null && !currentDeleteStatus) {
            result.addError("Record is not deleted, cannot restore");
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
    
    /**
     * Utility method to get current timestamp for audit fields
     */
    public static String getCurrentTimestamp() {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        return LocalDateTime.now().format(formatter);
    }
    
    /**
     * Utility method to check if a record should be included in analytics
     * (excludes soft deleted records)
     */
    public static boolean isActiveRecord(Boolean isDeleted) {
        return isDeleted == null || !isDeleted;
    }
} 