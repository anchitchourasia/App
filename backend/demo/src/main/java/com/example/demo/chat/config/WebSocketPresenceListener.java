package com.example.demo.chat.config;

import org.springframework.context.event.EventListener;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.messaging.SessionConnectedEvent;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;

import java.security.Principal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class WebSocketPresenceListener {

    private static final DateTimeFormatter TIME_FORMATTER =
            DateTimeFormatter.ofPattern("hh:mm a");

    private final SimpMessagingTemplate messagingTemplate;

    // sessionId -> userId
    private final Map<String, String> sessionUserMap = new ConcurrentHashMap<>();

    // userId -> sessionIds
    private final Map<String, Set<String>> userSessionsMap = new ConcurrentHashMap<>();

    public WebSocketPresenceListener(SimpMessagingTemplate messagingTemplate) {
        this.messagingTemplate = messagingTemplate;
    }

    @EventListener
    public void handleSessionConnected(SessionConnectedEvent event) {
        StompHeaderAccessor accessor = StompHeaderAccessor.wrap(event.getMessage());

        String sessionId = accessor.getSessionId();
        String userId = extractUserId(accessor);

        if (sessionId == null || userId == null || userId.isBlank()) {
            return;
        }

        sessionUserMap.put(sessionId, userId);
        userSessionsMap
                .computeIfAbsent(userId, key -> ConcurrentHashMap.newKeySet())
                .add(sessionId);

        publishPresence(userId, true);

        System.out.println("✅ WS CONNECTED: userId=" + userId + ", sessionId=" + sessionId);
    }

    @EventListener
    public void handleSessionDisconnect(SessionDisconnectEvent event) {
        String sessionId = event.getSessionId();
        if (sessionId == null || sessionId.isBlank()) {
            return;
        }

        String userId = sessionUserMap.remove(sessionId);
        if (userId == null || userId.isBlank()) {
            return;
        }

        Set<String> sessions = userSessionsMap.get(userId);
        if (sessions != null) {
            sessions.remove(sessionId);

            if (sessions.isEmpty()) {
                userSessionsMap.remove(userId);
                publishPresence(userId, false);
                System.out.println("🔌 WS DISCONNECTED: userId=" + userId + ", sessionId=" + sessionId);
            }
        }
    }

    public boolean isUserOnline(String userId) {
        if (userId == null || userId.isBlank()) {
            return false;
        }

        Set<String> sessions = userSessionsMap.get(userId);
        return sessions != null && !sessions.isEmpty();
    }

    private String extractUserId(StompHeaderAccessor accessor) {
        Principal principal = accessor.getUser();
        if (principal != null && principal.getName() != null && !principal.getName().isBlank()) {
            return principal.getName().trim();
        }

        Object attrUserId = accessor.getSessionAttributes() != null
                ? accessor.getSessionAttributes().get("userId")
                : null;

        if (attrUserId != null && !attrUserId.toString().isBlank()) {
            return attrUserId.toString().trim();
        }

        String nativeUserId = accessor.getFirstNativeHeader("userId");
        if (nativeUserId != null && !nativeUserId.isBlank()) {
            return nativeUserId.trim();
        }

        return null;
    }

    private void publishPresence(String userId, boolean online) {
        Map<String, Object> payload = new ConcurrentHashMap<>();
        payload.put("type", "PRESENCE");
        payload.put("userId", userId);
        payload.put("online", online);
        payload.put("timestamp", LocalDateTime.now().format(TIME_FORMATTER));
        payload.put("message", online ? "User is online" : "User is offline");

        messagingTemplate.convertAndSend("/topic/presence", payload);
    }
}
