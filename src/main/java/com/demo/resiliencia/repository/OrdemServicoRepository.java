package com.demo.resiliencia.repository;

import com.demo.resiliencia.model.OrdemServico;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface OrdemServicoRepository extends JpaRepository<OrdemServico, Long> {

    boolean existsByIntegrationId(String integrationId);

    Optional<OrdemServico> findByIntegrationId(String integrationId);

    List<OrdemServico> findAllByIntegrationId(String integrationId);

    @Query("SELECT o FROM OrdemServico o WHERE o.itens IS EMPTY")
    List<OrdemServico> findOrdensOrfas();
}
