package com.example.demo.insurance.dto.response;

public record InsuranceResponse(
    long id,
    String userId,
    String vehicleType,
    String vehicleNumber,
    String insuranceType,
    String validFrom,
    String validTo,
    String companyName,
    String status,
    String adminNote,
    String reviewedBy,
    String reviewedAt,
    String createdAt,
    boolean hasPdf
) {}
