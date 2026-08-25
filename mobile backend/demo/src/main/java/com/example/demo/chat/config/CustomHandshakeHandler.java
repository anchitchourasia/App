package com.example.demo.chat.config;

import java.security.Principal;
import java.util.Map;
import java.util.UUID;

import org.springframework.http.server.ServerHttpRequest;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.support.DefaultHandshakeHandler;
import org.springframework.web.util.UriComponentsBuilder;

@Component
public class CustomHandshakeHandler extends DefaultHandshakeHandler {

    @Override
    protected Principal determineUser(
            ServerHttpRequest request,
            WebSocketHandler wsHandler,
            Map<String, Object> attributes
    ) {
        String userId = extractUserId(request);

        if (userId == null || userId.isBlank()) {
            userId = "anon-" + UUID.randomUUID();
        } else {
            userId = userId.trim();
        }

        attributes.put("userId", userId);
        final String principalName = userId;

        return () -> principalName;
    }

    private String extractUserId(ServerHttpRequest request) {
        String userId = UriComponentsBuilder.fromUri(request.getURI())
                .build()
                .getQueryParams()
                .getFirst("userId");

        if (userId != null && !userId.isBlank()) {
            return userId.trim();
        }

        userId = request.getHeaders().getFirst("userId");
        if (userId != null && !userId.isBlank()) {
            return userId.trim();
        }

        return null;
    }
}
