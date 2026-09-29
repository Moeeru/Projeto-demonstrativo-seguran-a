package com.demo.resiliencia.repository;

import com.demo.resiliencia.model.AuditoriaTransacao;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AuditoriaTransacaoRepository extends JpaRepository<AuditoriaTransacao, Long> {

    List<AuditoriaTransacao> findAllByOrderByDataHoraDesc();

    List<AuditoriaTransacao> findAllByIntegrationIdOrderByDataHoraDesc(String integrationId);

    long countByTipoCenario(String tipoCenario);

    long countByStatusExecucao(String statusExecucao);
}
