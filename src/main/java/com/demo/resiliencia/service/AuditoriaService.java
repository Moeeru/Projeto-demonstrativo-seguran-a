package com.demo.resiliencia.service;

import com.demo.resiliencia.model.AuditoriaTransacao;
import com.demo.resiliencia.repository.AuditoriaTransacaoRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuditoriaService {

    private final AuditoriaTransacaoRepository repository;

    public AuditoriaService(AuditoriaTransacaoRepository repository) {
        this.repository = repository;
    }

    /**
     * Persiste o rastro de auditoria em transação AUTÔNOMA (REQUIRES_NEW).
     * Desta forma, mesmo se a transação do negócio sofrer ROLLBACK,
     * o registro de auditoria é commitado e comprova a ocorrência do evento.
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public AuditoriaTransacao registrar(String ipOrigem, String rota, String metodoHttp,
                                        String integrationId, String cliente, String tipoCenario,
                                        String statusExecucao, Integer codigoHttp, String detalhesTecnicos) {
        AuditoriaTransacao auditoria = new AuditoriaTransacao(
                ipOrigem, rota, metodoHttp, integrationId, cliente,
                tipoCenario, statusExecucao, codigoHttp, detalhesTecnicos
        );
        return repository.save(auditoria);
    }
}
