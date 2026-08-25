package com.example.demo.chat.config;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentMatchers;
import org.springframework.messaging.Message;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.messaging.SessionConnectedEvent;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;

import java.security.Principal;
import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

class WebSocketPresenceListenerTest {

    private SimpMessagingTemplate messagingTemplate;
    private WebSocketPresenceListener listener;

    @BeforeEach
    void setUp() {
        messagingTemplate = mock(SimpMessagingTemplate.class);
        listener = new WebSocketPresenceListener(messagingTemplate);
    }

    @Test
    void handleSessionConnected_withPrincipal_marksUserOnlineAndPublishes() {
        Message<byte[]> message = connectMessage("s1", principal("user1"), null, null);

        listener.handleSessionConnected(new SessionConnectedEvent(this, message));

        assertTrue(listener.isUserOnline("user1"));
        verify(messagingTemplate).convertAndSend(
                eq("/topic/presence"),
                ArgumentMatchers.<Object>argThat(payload -> {
                    Map<?, ?> map = (Map<?, ?>) payload;
                    return "PRESENCE".equals(map.get("type"))
                            && "user1".equals(map.get("userId"))
                            && Boolean.TRUE.equals(map.get("online"))
                            && "User is online".equals(map.get("message"))
                            && map.get("timestamp") != null;
                })
        );
    }

    @Test
    void handleSessionConnected_withSessionAttributeUserId_marksUserOnline() {
        Message<byte[]> message = connectMessage("s2", null, "user2", null);

        listener.handleSessionConnected(new SessionConnectedEvent(this, message));

        assertTrue(listener.isUserOnline("user2"));
        verify(messagingTemplate).convertAndSend(
                eq("/topic/presence"),
                ArgumentMatchers.<Object>argThat(payload -> {
                    Map<?, ?> map = (Map<?, ?>) payload;
                    return "user2".equals(map.get("userId"))
                            && Boolean.TRUE.equals(map.get("online"));
                })
        );
    }

    @Test
    void handleSessionConnected_withNativeHeaderUserId_marksUserOnline() {
        Message<byte[]> message = connectMessage("s3", null, null, "user3");

        listener.handleSessionConnected(new SessionConnectedEvent(this, message));

        assertTrue(listener.isUserOnline("user3"));
        verify(messagingTemplate).convertAndSend(
                eq("/topic/presence"),
                ArgumentMatchers.<Object>argThat(payload -> {
                    Map<?, ?> map = (Map<?, ?>) payload;
                    return "user3".equals(map.get("userId"))
                            && Boolean.TRUE.equals(map.get("online"));
                })
        );
    }

    @Test
    void handleSessionConnected_blankUserId_doesNothing() {
        Message<byte[]> message = connectMessage("s4", null, "   ", null);

        listener.handleSessionConnected(new SessionConnectedEvent(this, message));

        assertFalse(listener.isUserOnline("   "));
        verify(messagingTemplate, never()).convertAndSend(any(String.class), any(Object.class));
    }

    @Test
    void handleSessionDisconnect_blankSessionId_doesNothing() {
        SessionDisconnectEvent event = new SessionDisconnectEvent(
                this,
                MessageBuilder.withPayload(new byte[0]).build(),
                "",
                CloseStatus.NORMAL
        );

        listener.handleSessionDisconnect(event);

        verify(messagingTemplate, never()).convertAndSend(any(String.class), any(Object.class));
    }

    @Test
    void handleSessionDisconnect_unknownSession_doesNothing() {
        SessionDisconnectEvent event = new SessionDisconnectEvent(
                this,
                MessageBuilder.withPayload(new byte[0]).build(),
                "unknown-session",
                CloseStatus.NORMAL
        );

        listener.handleSessionDisconnect(event);

        verify(messagingTemplate, never()).convertAndSend(any(String.class), any(Object.class));
    }

    @Test
    void handleSessionDisconnect_lastSession_marksUserOfflineAndPublishes() {
        listener.handleSessionConnected(
                new SessionConnectedEvent(this, connectMessage("s5", principal("user5"), null, null))
        );
        reset(messagingTemplate);

        SessionDisconnectEvent event = new SessionDisconnectEvent(
                this,
                MessageBuilder.withPayload(new byte[0]).build(),
                "s5",
                CloseStatus.NORMAL
        );

        listener.handleSessionDisconnect(event);

        assertFalse(listener.isUserOnline("user5"));
        verify(messagingTemplate).convertAndSend(
                eq("/topic/presence"),
                ArgumentMatchers.<Object>argThat(payload -> {
                    Map<?, ?> map = (Map<?, ?>) payload;
                    return "PRESENCE".equals(map.get("type"))
                            && "user5".equals(map.get("userId"))
                            && Boolean.FALSE.equals(map.get("online"))
                            && "User is offline".equals(map.get("message"))
                            && map.get("timestamp") != null;
                })
        );
    }

    @Test
    void handleSessionDisconnect_oneOfMultipleSessions_keepsUserOnline() {
        listener.handleSessionConnected(
                new SessionConnectedEvent(this, connectMessage("s6a", principal("user6"), null, null))
        );
        listener.handleSessionConnected(
                new SessionConnectedEvent(this, connectMessage("s6b", principal("user6"), null, null))
        );
        reset(messagingTemplate);

        SessionDisconnectEvent event = new SessionDisconnectEvent(
                this,
                MessageBuilder.withPayload(new byte[0]).build(),
                "s6a",
                CloseStatus.NORMAL
        );

        listener.handleSessionDisconnect(event);

        assertTrue(listener.isUserOnline("user6"));
        verify(messagingTemplate, never()).convertAndSend(any(String.class), any(Object.class));
    }

    @Test
    void isUserOnline_nullOrBlank_returnsFalse() {
        assertFalse(listener.isUserOnline(null));
        assertFalse(listener.isUserOnline(""));
        assertFalse(listener.isUserOnline("   "));
    }

    private Message<byte[]> connectMessage(
            String sessionId,
            Principal principal,
            String sessionAttrUserId,
            String nativeHeaderUserId
    ) {
        StompHeaderAccessor accessor = StompHeaderAccessor.create(StompCommand.CONNECTED);
        accessor.setSessionId(sessionId);

        if (principal != null) {
            accessor.setUser(principal);
        }

        Map<String, Object> sessionAttributes = new HashMap<>();
        if (sessionAttrUserId != null) {
            sessionAttributes.put("userId", sessionAttrUserId);
        }
        accessor.setSessionAttributes(sessionAttributes);

        if (nativeHeaderUserId != null) {
            accessor.addNativeHeader("userId", nativeHeaderUserId);
        }

        accessor.setLeaveMutable(true);
        return MessageBuilder.createMessage(new byte[0], accessor.getMessageHeaders());
    }

    private Principal principal(String name) {
        return () -> name;
    }
}