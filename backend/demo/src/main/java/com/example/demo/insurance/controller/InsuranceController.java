package com.example.demo.insurance.controller;


import com.example.demo.insurance.dto.request.CreateInsuranceRequest;
import com.example.demo.insurance.dto.request.UpdateStatusRequest;
import com.example.demo.insurance.dto.response.InsuranceResponse;
import com.example.demo.insurance.repository.InsuranceFileRepository;
import com.example.demo.insurance.service.InsuranceService;
import org.springframework.core.io.InputStreamResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;


import java.io.IOException;  // ✅ FIX: added specific import
import java.util.List;


@RestController
@RequestMapping("/api")
public class InsuranceController {


  private final InsuranceService service;


  public InsuranceController(InsuranceService service) {
    this.service = service;
  }


  // CREATE
  @PostMapping("/insurance")
  public ResponseEntity<Long> create(@RequestBody CreateInsuranceRequest r) {
    return ResponseEntity.ok(service.create(r));
  }


  // LIST (old - query param) -> keep it so older app still works
  @GetMapping("/insurance")
  public List<InsuranceResponse> listForUser(@RequestParam String userId) {
    return service.listUser(userId);
  }


  // LIST (new - path variable) -> required for your updated Flutter
  @GetMapping("/insurance/user/{userId}")
  public List<InsuranceResponse> listForUserPath(@PathVariable String userId) {
    return service.listUser(userId);
  }


  // ADMIN LIST
  @GetMapping("/insurance/admin")
  public List<InsuranceResponse> listForAdmin(@RequestParam(required = false) String status) {
    return service.listAdmin(status);
  }


  // DETAILS BY ID
  // IMPORTANT: numeric-only regex prevents conflict with "/insurance/notifications"
  @GetMapping("/insurance/{id:\\d+}")
  public ResponseEntity<InsuranceResponse> getById(@PathVariable long id) {
    return ResponseEntity.ok(service.getById(id));
  }


  // UPDATE STATUS
  @PatchMapping("/insurance/{id:\\d+}")
  public ResponseEntity<Void> updateStatus(@PathVariable long id, @RequestBody UpdateStatusRequest r) {
    service.updateStatus(id, r);
    return ResponseEntity.ok().build();
  }


  // UPLOAD PDF
  @PostMapping(value = "/insurance/{id:\\d+}/pdf", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
  public ResponseEntity<Void> uploadPdf(
      @PathVariable long id,
      @RequestPart("file") MultipartFile file,
      @RequestPart("uploadedBy") String uploadedBy
  ) throws IOException {  // ✅ FIX: throws IOException instead of throws Exception
    service.uploadPdf(id, file, uploadedBy);
    return ResponseEntity.ok().build();
  }


  // DOWNLOAD PDF
  @GetMapping("/insurance/{id:\\d+}/pdf")
  public ResponseEntity<InputStreamResource> downloadPdf(@PathVariable long id) {
    InsuranceFileRepository.PdfRow pdf = service.downloadPdf(id);


    return ResponseEntity.ok()
        .contentType(MediaType.parseMediaType(pdf.mimeType()))
        .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + pdf.fileName() + "\"")
        .body(new InputStreamResource(pdf.stream()));
  }


  // NOTIFICATIONS (derived, no new table)
  // GET /api/insurance/notifications?userId=admin11
  @GetMapping("/insurance/notifications")
  public List<InsuranceResponse> notifications(@RequestParam String userId) {
    return service.listUserNotifications(userId);
  }
}