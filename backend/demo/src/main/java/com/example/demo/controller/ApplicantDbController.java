package com.example.demo.controller;

import com.example.demo.dto.ApplicantListItemDto;
import com.example.demo.service.ApplicantDbService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/applicants")
public class ApplicantDbController {

  private final ApplicantDbService service;

  public ApplicantDbController(ApplicantDbService service) {
    this.service = service;
  }

  // /api/applicants            -> all (263)
  // /api/applicants?limit=10   -> top 10
  @GetMapping
  public List<ApplicantListItemDto> list(@RequestParam(required = false) Integer limit) {
    if (limit == null) {
      return service.getAllApplicants();
    }
    if (limit <= 0) {
      return List.of();
    }
    return service.getTopApplicants(limit);
  }
}
