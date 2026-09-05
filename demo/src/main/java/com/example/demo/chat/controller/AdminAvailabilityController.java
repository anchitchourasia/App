package com.example.demo.chat.controller;

import com.example.demo.chat.config.AdminAvailabilityService;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;

@RestController
@RequestMapping("/api/chat")
@CrossOrigin(origins = "*")
public class AdminAvailabilityController {

    private static final DateTimeFormatter TIME_FORMATTER =
            DateTimeFormatter.ofPattern("hh:mm a");

    private final AdminAvailabilityService availabilityService;
    private final SimpMessagingTemplate messagingTemplate;

    public AdminAvailabilityController(
            AdminAvailabilityService availabilityService,
            SimpMessagingTemplate messagingTemplate
    ) {
        this.availabilityService = availabilityService;
        this.messagingTemplate = messagingTemplate;
    }

    @PostMapping("/availability/{userId}")
    public ResponseEntity<Map<String, Object>> setAvailability(
            @PathVariable String userId,
            @RequestParam boolean available
    ) {
        if (userId == null || userId.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of(
                    "ok", false,
                    "error", "userId is required"
            ));
        }

        // Set purely manual availability
        availabilityService.setAvailable(userId, available);

        // Broadcast presence change to anyone listening on /topic/presence
        messagingTemplate.convertAndSend("/topic/presence", Map.of(
                "type", "PRESENCE",
                "userId", userId,
                "online", available,
                "timestamp", LocalDateTime.now().format(TIME_FORMATTER),
                "message", available ? "Admin is online" : "Admin is offline"
        ));

        return ResponseEntity.ok(Map.of(
                "ok", true,
                "userId", userId,
                "online", available,
                "message", available ? "You are now visible as online" : "You are now visible as offline",
                "timestamp", LocalDateTime.now().format(TIME_FORMATTER)
        ));
    }

    @GetMapping("/availability/{userId}")
    public ResponseEntity<Map<String, Object>> getAvailability(@PathVariable String userId) {
        // Fetch purely manual availability (no WebSocket checks)
        boolean manualOnline = availabilityService.isAvailable(userId);

        return ResponseEntity.ok(Map.of(
                "userId", userId,
                "manualOnline", manualOnline,
                "online", manualOnline,
                "message", manualOnline ? "Admin is online" : "Admin is offline"
        ));
    }
}
