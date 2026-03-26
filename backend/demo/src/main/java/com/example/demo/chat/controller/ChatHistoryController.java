package com.example.demo.chat.controller;

import com.example.demo.chat.config.AdminAvailabilityService;
import com.example.demo.chat.dto.ChatMessage;
import com.example.demo.chat.entity.ChatMessageEntity;
import com.example.demo.chat.service.ChatPersistenceService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/chat")
@CrossOrigin(origins = "*")
public class ChatHistoryController {

    private static final DateTimeFormatter TIME_FORMATTER =
            DateTimeFormatter.ofPattern("hh:mm a");

    private final ChatPersistenceService chatPersistenceService;
    private final SimpMessagingTemplate messagingTemplate;
    private final AdminAvailabilityService availabilityService;

    public ChatHistoryController(
            ChatPersistenceService chatPersistenceService,
            SimpMessagingTemplate messagingTemplate,
            AdminAvailabilityService availabilityService
    ) {
        this.chatPersistenceService = chatPersistenceService;
        this.messagingTemplate = messagingTemplate;
        this.availabilityService = availabilityService;
    }

    @GetMapping("/history/{user1}/{user2}")
    public ResponseEntity<List<ChatMessageEntity>> getHistory(
            @PathVariable String user1,
            @PathVariable String user2
    ) {
        return ResponseEntity.ok(chatPersistenceService.getHistory(user1, user2));
    }

    @GetMapping("/presence/{userId}")
    public ResponseEntity<Map<String, Object>> getPresence(@PathVariable String userId) {
        final String targetUserId = safe(userId);
        
        // 100% PURE MANUAL DETECTION
        boolean online = availabilityService.isAvailable(targetUserId);

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("userId", targetUserId);
        body.put("online", online);
        body.put("message", online ? "Admin is online" : "Admin is offline");
        body.put("timestamp", LocalDateTime.now().format(TIME_FORMATTER));

        return ResponseEntity.ok(body);
    }

    @PostMapping("/send")
    public ResponseEntity<Map<String, Object>> sendMessage(@RequestBody ChatMessage chatMessage) {
        if (chatMessage == null) return ResponseEntity.badRequest().build();

        String senderId = safe(chatMessage.getSenderId());
        String receiverId = safe(chatMessage.getReceiverId());
        String senderName = safe(chatMessage.getSenderName());
        String message = safe(chatMessage.getMessage());

        if (senderId.isBlank() || receiverId.isBlank() || message.isBlank()) {
            return ResponseEntity.badRequest().build();
        }

        boolean receiverIsAdmin = receiverId.toLowerCase().contains("admin");
        boolean receiverOnline = availabilityService.isAvailable(receiverId);

        // STRICT BLOCK: If a user is sending TO the admin, and Admin is offline -> BLOCK IT
        if (receiverIsAdmin && !receiverOnline) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of(
                    "ok", false,
                    "online", false,
                    "error", "Admin is offline. You cannot send messages right now."
            ));
        }

        // Otherwise (or if Admin is sending to Employee), ALWAYS save & send
        chatMessage.setSenderId(senderId);
        chatMessage.setReceiverId(receiverId);
        chatMessage.setSenderName(senderName);
        chatMessage.setMessage(message);
        chatMessage.setTimestamp(LocalDateTime.now().format(TIME_FORMATTER));

        chatPersistenceService.saveMessage(chatMessage);

        try {
            messagingTemplate.convertAndSendToUser(receiverId, "/queue/messages", chatMessage);
            messagingTemplate.convertAndSendToUser(senderId, "/queue/messages", chatMessage);
            messagingTemplate.convertAndSendToUser(senderId, "/queue/status", Map.of(
                    "type", "CHAT_STATUS",
                    "success", true,
                    "message", "Message delivered",
                    "targetUserId", receiverId,
                    "timestamp", chatMessage.getTimestamp()
            ));
        } catch (Exception ignored) {}

        return ResponseEntity.ok(Map.of("ok", true, "online", receiverOnline, "timestamp", chatMessage.getTimestamp()));
    }

    @GetMapping("/conversations/{adminId}")
    public ResponseEntity<List<Map<String, String>>> getConversations(@PathVariable String adminId) {
        return ResponseEntity.ok(chatPersistenceService.getConversationsForAdmin(adminId));
    }

    private String safe(String value) {
        return value == null ? "" : value.trim();
    }
}
