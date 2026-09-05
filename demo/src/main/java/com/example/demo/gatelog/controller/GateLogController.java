package com.example.demo.gatelog.controller;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.Optional;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.demo.gatelog.dto.GateLogRequest;
import com.example.demo.gatelog.entity.GateLogEntity;
import com.example.demo.gatelog.repository.GateLogRepository;

@RestController
@RequestMapping("/cvps/api/gate-logs")
public class GateLogController {

    private final GateLogRepository gateLogRepository;

    public GateLogController(GateLogRepository gateLogRepository) {
        this.gateLogRepository = gateLogRepository;
    }

    @PostMapping
    public ResponseEntity<?> createGateLog(
            @RequestBody GateLogRequest request) {

        if (request == null) {
            return badRequest("Request body is required");
        }

        if (request.getPermissionNo() == null
                || request.getPermissionNo() <= 0) {
            return badRequest("permissionNo must be greater than zero");
        }

        if (request.getEnterBy() == null
                || request.getEnterBy().trim().isEmpty()) {
            return badRequest("enterBy is required");
        }

        String action = normalizeAction(request.getAction());

        if (action == null) {
            return badRequest("action must be IN or OUT");
        }

        Optional<GateLogEntity> latestLogOptional =
                gateLogRepository
                        .findTopByPermissionNoOrderByGateLogIdDesc(
                                request.getPermissionNo()
                        );

        if (latestLogOptional.isEmpty()) {
            if (!"IN".equals(action)) {
                return conflict(
                        "First gate action must be IN for Permission No. "
                                + request.getPermissionNo()
                );
            }
        } else {
            String lastAction = latestLogOptional
                    .get()
                    .getAction()
                    .trim()
                    .toUpperCase();

            if (lastAction.equals(action)) {
                return conflict(
                        "Gate " + action
                                + " is not allowed for Permission No. "
                                + request.getPermissionNo()
                                + ". Last recorded action is "
                                + lastAction
                                + "."
                );
            }
        }

        LocalTime now = LocalTime.now();

        GateLogEntity entity = new GateLogEntity();
        entity.setPermissionNo(request.getPermissionNo());
        entity.setAction(action);
        entity.setActionDate(LocalDate.now());
        entity.setActionTime(
                now.format(DateTimeFormatter.ofPattern("HH:mm:ss"))
        );
        entity.setEnterBy(request.getEnterBy().trim());
        entity.setCreatedAt(LocalDateTime.now());

        GateLogEntity saved = gateLogRepository.save(entity);

        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(saved);
    }

    @GetMapping("/{permissionNo}/latest")
    public ResponseEntity<?> getLatestGateAction(
            @PathVariable Integer permissionNo) {

        if (permissionNo == null || permissionNo <= 0) {
            return badRequest("permissionNo must be greater than zero");
        }

        Optional<GateLogEntity> latestLogOptional =
                gateLogRepository
                        .findTopByPermissionNoOrderByGateLogIdDesc(
                                permissionNo
                        );

        if (latestLogOptional.isEmpty()) {
            return ResponseEntity.ok(
                    Map.of(
                            "permissionNo", permissionNo,
                            "lastAction", ""
                    )
            );
        }

        GateLogEntity latestLog = latestLogOptional.get();

        return ResponseEntity.ok(
                Map.of(
                        "permissionNo", permissionNo,
                        "lastAction", latestLog.getAction(),
                        "gateLogId", latestLog.getGateLogId(),
                        "enterBy", latestLog.getEnterBy(),
                        "actionDate", latestLog.getActionDate().toString(),
                        "actionTime", latestLog.getActionTime()
                )
        );
    }

    private String normalizeAction(String action) {
        if (action == null) {
            return null;
        }

        String normalizedAction = action.trim().toUpperCase();

        if ("IN".equals(normalizedAction)
                || "OUT".equals(normalizedAction)) {
            return normalizedAction;
        }

        return null;
    }

    private ResponseEntity<Map<String, String>> badRequest(String message) {
        return ResponseEntity
                .badRequest()
                .body(Map.of("message", message));
    }

    private ResponseEntity<Map<String, String>> conflict(String message) {
        return ResponseEntity
                .status(HttpStatus.CONFLICT)
                .body(Map.of("message", message));
    }
}