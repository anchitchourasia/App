package com.example.demo.insurance.service;

import com.example.demo.insurance.dto.request.CreateInsuranceRequest;
import com.example.demo.insurance.dto.request.UpdateStatusRequest;
import com.example.demo.insurance.dto.response.InsuranceResponse;
import com.example.demo.insurance.exception.NotFoundException;
import com.example.demo.insurance.repository.InsuranceFileRepository;
import com.example.demo.insurance.repository.InsuranceRepository;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@Service
public class InsuranceService {

  private final InsuranceRepository repo;
  private final InsuranceFileRepository fileRepo;

  public InsuranceService(InsuranceRepository repo, InsuranceFileRepository fileRepo) {
    this.repo = repo;
    this.fileRepo = fileRepo;
  }

  public long create(CreateInsuranceRequest r) {
    return repo.insertUpload(
        r.userId(),
        r.vehicleType(),
        r.vehicleNumber(),
        r.insuranceType(),
        r.validFrom(),
        r.validTo(),
        r.companyName()
    );
  }

  public List<InsuranceResponse> listUser(String userId) {
    return repo.listForUser(userId);
  }

  public List<InsuranceResponse> listAdmin(String status) {
    return repo.listForAdmin(status);
  }

  // Details page
  public InsuranceResponse getById(long id) {
    return repo.findById(id)
        .orElseThrow(() -> new NotFoundException("Insurance id not found: " + id));
  }

  public void updateStatus(long id, UpdateStatusRequest r) {
    int updated = repo.updateStatus(id, r.status(), r.reviewedBy(), r.adminNote());
    if (updated == 0) throw new NotFoundException("Insurance id not found: " + id);
  }

  public void uploadPdf(long id, MultipartFile file, String uploadedBy) throws Exception {
    if (repo.getOwnerUserId(id).isEmpty()) {
      throw new NotFoundException("Insurance id not found: " + id);
    }

    if (file == null || file.isEmpty()) {
      throw new IllegalArgumentException("File is empty");
    }

    String name = (file.getOriginalFilename() == null || file.getOriginalFilename().isBlank())
        ? ("insurance_" + id + ".pdf")
        : file.getOriginalFilename();

    String mime = (file.getContentType() == null || file.getContentType().isBlank())
        ? "application/pdf"
        : file.getContentType();

    fileRepo.savePdf(
        id,
        name,
        mime,
        file.getSize(),
        file.getInputStream(),
        uploadedBy
    );
  }

  public InsuranceFileRepository.PdfRow downloadPdf(long id) {
    return fileRepo.loadPdf(id)
        .orElseThrow(() -> new NotFoundException("PDF not found for id: " + id));
  }

  // NEW: derived notifications (no extra table)
  public List<InsuranceResponse> listUserNotifications(String userId) {
    return repo.listNotificationsForUser(userId);
  }
}
