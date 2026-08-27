package com.example.demo.chat.controller;

import com.example.demo.chat.config.WebSocketPresenceListener;
import com.example.demo.chat.dto.ChatMessage;
import com.example.demo.chat.service.ChatPersistenceService;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.Map;

@Controller
public class ChatController {

    private static final DateTimeFormatter TIME_FORMATTER =
            DateTimeFormatter.ofPattern("hh:mm a");

    private final SimpMessagingTemplate messagingTemplate;
    private final ChatPersistenceService chatPersistenceService;
    private final WebSocketPresenceListener presenceListener;

    public ChatController(
            SimpMessagingTemplate messagingTemplate,
            ChatPersistenceService chatPersistenceService,
            WebSocketPresenceListener presenceListener
    ) {
        this.messagingTemplate = messagingTemplate;
        this.chatPersistenceService = chatPersistenceService;
        this.presenceListener = presenceListener;
    }

    @MessageMapping("/chat.send")
    public void sendMessage(@Payload ChatMessage chatMessage) {
        if (chatMessage == null) return;

        final String senderId   = safe(chatMessage.getSenderId());
        final String receiverId = safe(chatMessage.getReceiverId());
        final String senderName = safe(chatMessage.getSenderName());
        final String message    = safe(chatMessage.getMessage());

        // Only reject truly empty/invalid payloads
        if (senderId.isBlank() || receiverId.isBlank() || message.isBlank()) {
            sendStatusToUser(senderId, false, "Invalid chat payload", receiverId);
            return;
        }

        // ✅ REMOVED: presenceListener.isUserOnline(receiverId) check
        // Messages must ALWAYS be saved and delivered regardless of
        // WebSocket connection state. Polling will pick it up on the
        // receiver side if they are not connected via socket right now.

        chatMessage.setSenderId(senderId);
        chatMessage.setReceiverId(receiverId);
        chatMessage.setSenderName(senderName);
        chatMessage.setMessage(message);
        chatMessage.setTimestamp(LocalDateTime.now().format(TIME_FORMATTER));

        // Step 1: Always save to DB first
        chatPersistenceService.saveMessage(chatMessage);

        // Step 2: Push to receiver (works if they are on WebSocket;
        // if not, they will get it via polling /api/chat/history)
        messagingTemplate.convertAndSendToUser(
                receiverId,
                "/queue/messages",
                chatMessage
        );

        // Step 3: Push back to sender so their UI confirms delivery
        messagingTemplate.convertAndSendToUser(
                senderId,
                "/queue/messages",
                chatMessage
        );

        // Step 4: Notify sender of success
        sendStatusToUser(senderId, true, "Message delivered", receiverId);
    }

    @MessageMapping("/presence.check")
    public void checkPresence(@Payload Map<String, String> payload) {
        if (payload == null) return;

        final String requesterId  = safe(payload.get("requesterId"));
        final String targetUserId = safe(payload.get("targetUserId"));

        if (requesterId.isBlank() || targetUserId.isBlank()) return;

        final boolean online = presenceListener.isUserOnline(targetUserId);

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("type",      "PRESENCE");
        response.put("userId",    targetUserId);
        response.put("online",    online);
        response.put("message",   online ? "Online" : "Offline");
        response.put("timestamp", LocalDateTime.now().format(TIME_FORMATTER));

        messagingTemplate.convertAndSendToUser(
                requesterId,
                "/queue/status",
                response
        );
    }

    private void sendStatusToUser(
            String userId,
            boolean success,
            String message,
            String targetUserId
    ) {
        if (userId == null || userId.isBlank()) return;

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("type",         "CHAT_STATUS");
        response.put("success",      success);
        response.put("message",      message);
        response.put("targetUserId", targetUserId);
        response.put("timestamp",    LocalDateTime.now().format(TIME_FORMATTER));

        messagingTemplate.convertAndSendToUser(
                userId,
                "/queue/status",
                response
        );
    }

    private String safe(String value) {
        return value == null ? "" : value.trim();
    }
}
