package com.example.demo.gatelog.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.demo.gatelog.entity.GateLogEntity;

@Repository
public interface GateLogRepository
        extends JpaRepository<GateLogEntity, Long> {

    Optional<GateLogEntity> findTopByPermissionNoOrderByGateLogIdDesc(
            Integer permissionNo
    );
}