package com.example.demo.chat.config;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServletServerHttpRequest;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.server.support.DefaultHandshakeHandler;

import java.security.Principal;
import java.util.Map;

@Component
public class UserHandshakeHandler extends DefaultHandshakeHandler {

    @Override
    protected Principal determineUser(
            ServerHttpRequest request,
            WebSocketHandler wsHandler,
            Map<String, Object> attributes
    ) {
        if (request instanceof ServletServerHttpRequest servletRequest) {
            HttpServletRequest http = servletRequest.getServletRequest();

            String userId = http.getParameter("userId");
            if (userId == null || userId.isBlank()) {
                userId = http.getHeader("userId");
            }

            if (userId != null && !userId.isBlank()) {
                final String finalUserId = userId.trim();
                return () -> finalUserId;
            }
        }

        return super.determineUser(request, wsHandler, attributes);
    }
}
