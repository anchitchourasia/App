package com.example.demo.service;

import com.example.demo.dto.ApplicantListItemDto;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ApplicantDbService {

  private final JdbcTemplate jdbc;

  public ApplicantDbService(JdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  // ✅ All rows (263)
  public List<ApplicantListItemDto> getAllApplicants() {
    String sql =
        "SELECT " +
        "  'APP' || LPAD(TO_CHAR(ID), 5, '0') AS applicant_id, " +
        "  TRIM(TRIM(NVL(FIRST_NAME, '')) || ' ' || TRIM(NVL(LAST_NAME, ''))) AS applicant_name " +
        "FROM AMS_APPLICANT_DETAILS " +
        "ORDER BY ID DESC";

    return jdbc.query(
        sql,
        (rs, rowNum) -> new ApplicantListItemDto(
            rs.getString("applicant_id"),
            rs.getString("applicant_name")
        )
    );
  }

  // ✅ Top N rows when limit is provided
  public List<ApplicantListItemDto> getTopApplicants(int limit) {
    int safeLimit = Math.max(limit, 1); // no 100 cap now

    String sql =
        "SELECT * FROM ( " +
        "  SELECT " +
        "    'APP' || LPAD(TO_CHAR(ID), 5, '0') AS applicant_id, " +
        "    TRIM(TRIM(NVL(FIRST_NAME, '')) || ' ' || TRIM(NVL(LAST_NAME, ''))) AS applicant_name " +
        "  FROM AMS_APPLICANT_DETAILS " +
        "  ORDER BY ID DESC " +
        ") FETCH FIRST ? ROWS ONLY";

    return jdbc.query(
        sql,
        (rs, rowNum) -> new ApplicantListItemDto(
            rs.getString("applicant_id"),
            rs.getString("applicant_name")
        ),
        safeLimit
    );
  }
}
