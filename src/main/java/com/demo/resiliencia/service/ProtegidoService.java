package com.demo.resiliencia.service;

import com.demo.resiliencia.dto.ItemOrdemRequest;
import com.demo.resiliencia.dto.OrdemServicoRequest;
import com.demo.resiliencia.dto.OrdemServicoResponse;
import com.demo.resiliencia.exception.InjecaoDeFalhaException;
import com.demo.resiliencia.model.ItemOrdem;
import com.demo.resiliencia.model.OrdemServico;
import com.demo.resiliencia.repository.ItemOrdemRepository;
import com.demo.resiliencia.repository.OrdemServicoRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Optional;

@Service
public class ProtegidoService {

    private final OrdemServicoRepository ordemRepository;
    private final ItemOrdemRepository itemRepository;
    private final AuditoriaService auditoriaService;

    public ProtegidoService(OrdemServicoRepository ordemRepository,
                            ItemOrdemRepository itemRepository,
                            AuditoriaService auditoriaService) {
        this.ordemRepository = ordemRepository;
        this.itemRepository = itemRepository;
        this.auditoriaService = auditoriaService;
    }

    /**
     * ROTA RESILIENTE:
     * 1. Idempotência: Checa se o integration_id já foi processado anteriormente.
     * 2. Atomicidade: @Transactional garante Rollback total caso ocorra qualquer erro no meio do processo.
     * 3. Fail-Fast: O Controller usa @Valid, mas mesmo se uma inconsistência passar, a transação protege o banco.
     */
    public OrdemServicoResponse processarOrdemProtegida(OrdemServicoRequest request, boolean simularFalhaNoMeio) {
        return processarOrdemProtegida(request, simularFalhaNoMeio, "127.0.0.1");
    }

    @Transactional(rollbackFor = Exception.class)
    public OrdemServicoResponse processarOrdemProtegida(OrdemServicoRequest request,
                                                        boolean simularFalhaNoMeio,
                                                        String ipOrigem) {
        // PROTEÇÃO 2: IDEMPOTÊNCIA
        // Se este integration_id já foi recebido (ex: reenvio de webhook ou retry attack),
        // retorna o registro existente sem reprocessar e sem duplicar dados.
        Optional<OrdemServico> existente = ordemRepository.findByIntegrationId(request.getIntegrationId());
        if (existente.isPresent()) {
            auditoriaService.registrar(
                    ipOrigem,
                    "/api/protegido/ordens",
                    "POST",
                    request.getIntegrationId(),
                    request.getCliente(),
                    "CENARIO_5_IDEMPOTENCIA",
                    "IDEMPOTENCIA_DEDUPLICADA",
                    200,
                    "IDEMPOTÊNCIA ATIVA: Chave '" + request.getIntegrationId()
                            + "' já cadastrada. Ordem ID=" + existente.get().getId()
                            + " reaproveitada sem novo INSERT no PostgreSQL."
            );

            return new OrdemServicoResponse(
                    existente.get(),
                    "IDEMPOTÊNCIA ATIVA: Esta ordem (integration_id=" + request.getIntegrationId() 
                    + ") já havia sido gravada. Nenhuma duplicata foi criada no banco de dados."
            );
        }

        // PROTEÇÃO 1: ATOMICIDADE (@Transactional)
        OrdemServico ordem = new OrdemServico(request.getCliente(), request.getIntegrationId());
        ordem.setStatus("PROCESSADO_COM_SUCESSO");
        ordem = ordemRepository.save(ordem);

        if (request.getItens() != null) {
            for (ItemOrdemRequest itemReq : request.getItens()) {
                // Simulação de falha no meio do processo para demonstrar o ROLLBACK
                if (simularFalhaNoMeio || (itemReq.getValor() != null && itemReq.getValor().compareTo(BigDecimal.ZERO) < 0)) {
                    // Como auditoriaService usa REQUIRES_NEW, esta evidência será commitada
                    // no banco mesmo quando a ordem for revertida pelo Rollback!
                    auditoriaService.registrar(
                            ipOrigem,
                            "/api/protegido/ordens",
                            "POST",
                            request.getIntegrationId(),
                            request.getCliente(),
                            "CENARIO_4_ATOMICIDADE_ROLLBACK",
                            "ROLLBACK_AUTOMATICO_EXECUTADO",
                            500,
                            "ATOMICIDADE ACID: Exceção simulada durante persistência dos itens. "
                                    + "O @Transactional interceptou a falha e acionou ROLLBACK total. "
                                    + "Ordem mestre desfeita no PostgreSQL (Zero ordens órfãs)!"
                    );

                    throw new InjecaoDeFalhaException(
                            "Injeção de Falha com Proteção: Ocorreu um erro no processamento do item. "
                            + "Graças ao @Transactional, a transação será revertida (ROLLBACK COMPLETO) "
                            + "e NADA foi persistido no banco de dados!"
                    );
                }

                ItemOrdem item = new ItemOrdem(itemReq.getDescricao(), itemReq.getValor(), ordem);
                itemRepository.save(item);
                ordem.adicionarItem(item);
            }
        }

        auditoriaService.registrar(
                ipOrigem,
                "/api/protegido/ordens",
                "POST",
                request.getIntegrationId(),
                request.getCliente(),
                "CENARIO_RESILIENTE",
                "SUCESSO_TRANSACIONAL",
                201,
                "Ordem ID=" + ordem.getId() + " gravada com 100% de integridade e atomicidade."
        );

        return new OrdemServicoResponse(ordem, "Ordem gravada com sucesso com proteção transacional e controle de idempotência.");
    }
}
