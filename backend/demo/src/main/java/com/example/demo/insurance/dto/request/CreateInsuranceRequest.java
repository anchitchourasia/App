package com.example.demo.insurance.dto.request;

public record CreateInsuranceRequest(
    String userId,
    String vehicleType,
    String vehicleNumber,
    String insuranceType,
    String validFrom,   // YYYY-MM-DD
    String validTo,     // YYYY-MM-DD
    String companyName
) {}
