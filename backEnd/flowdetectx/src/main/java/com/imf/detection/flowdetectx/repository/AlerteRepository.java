package com.imf.detection.flowdetectx.repository;

import com.imf.detection.flowdetectx.model.Alerte;
import com.imf.detection.flowdetectx.model.enums.CriticiteEnum;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AlerteRepository extends JpaRepository<Alerte, Long> {

    List<Alerte> findBySimulationIdOrderByHorodatageDesc(Long simulationId);

    List<Alerte> findByCriticiteOrderByHorodatageDesc(CriticiteEnum criticite);

    List<Alerte> findAllByOrderByHorodatageDesc();
}
