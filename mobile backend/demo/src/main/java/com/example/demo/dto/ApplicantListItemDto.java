package com.example.demo.dto;

public class ApplicantListItemDto {

  private final String applicantId;
  private final String applicantName;

  public ApplicantListItemDto(String applicantId, String applicantName) {
    this.applicantId = applicantId;
    this.applicantName = applicantName;
  }

  public String getApplicantId() {
    return applicantId;
  }

  public String getApplicantName() {
    return applicantName;
  }
}
