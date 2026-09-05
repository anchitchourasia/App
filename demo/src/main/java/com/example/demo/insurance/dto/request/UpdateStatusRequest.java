package com.example.demo.insurance.dto.request;

public record UpdateStatusRequest(
    String status,      // APPROVED / MODIFY / PENDING
    String reviewedBy,
    String adminNote
) {}
