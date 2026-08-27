package com.example.demo.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

@Component
public class ApiKeyFilter extends OncePerRequestFilter {

  @Value("${app.api-key}")
  private String expectedApiKey;

  @Override
  protected boolean shouldNotFilter(HttpServletRequest request) {
    String path = request.getRequestURI();
    return path == null || !path.startsWith("/api/");
  }

  @Override
  protected void doFilterInternal(HttpServletRequest request,
                                  HttpServletResponse response,
                                  FilterChain filterChain) throws ServletException, IOException {

    String providedKey = request.getHeader("X-API-KEY");

    if (providedKey == null || providedKey.isBlank()) {
      response.setStatus(HttpStatus.UNAUTHORIZED.value());
      response.setContentType("application/json");
      response.getWriter().write("{\"error\":\"Missing X-API-KEY\"}");
      return;
    }

    if (!providedKey.equals(expectedApiKey)) {
      response.setStatus(HttpStatus.FORBIDDEN.value());
      response.setContentType("application/json");
      response.getWriter().write("{\"error\":\"Invalid X-API-KEY\"}");
      return;
    }

    // Mark request as authenticated for Spring Security
    if (SecurityContextHolder.getContext().getAuthentication() == null) {
      var auth = new UsernamePasswordAuthenticationToken(
          "api-key-client",               // principal
          null,                           // credentials
          List.of(new SimpleGrantedAuthority("ROLE_API"))
      );
      SecurityContextHolder.getContext().setAuthentication(auth);
    }

    filterChain.doFilter(request, response);
  }
}
