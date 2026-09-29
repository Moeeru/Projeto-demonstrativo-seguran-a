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

import java.math.BigDecimal;

@Service
public class VulneravelService {

    private final OrdemServicoRepository ordemRepository;
    private final ItemOrdemRepository itemRepository;
    private final AuditoriaService auditoriaService;

    public VulneravelService(OrdemServicoRepository ordemRepository,
                             ItemOrdemRepository itemRepository,
                             AuditoriaService auditoriaService) {
        this.ordemRepository = ordemRepository;
        this.itemRepository = itemRepository;
        this.auditoriaService = auditoriaService;
    }

    /**
     * ROTA DO CAOS:
     * 1. NÃO tem @Transactional (sem atomicidade).
     * 2. NÃO verifica integration_id (sem idempotência, aceita duplicatas).
     * 3. Injeção de Falha (Partial Commit): ao encontrar item com valor negativo, interrompe a execução
     *    após já ter persistido a OrdemServico no banco, gerando registro órfão.
     */
    public OrdemServicoResponse processarOrdemVulneravel(OrdemServicoRequest request) {
        return processarOrdemVulneravel(request, "127.0.0.1");
    }

    public OrdemServicoResponse processarOrdemVulneravel(OrdemServicoRequest request, String ipOrigem) {
        boolean jaExistia = request.getIntegrationId() != null && ordemRepository.existsByIntegrationId(request.getIntegrationId());

        // Passo 1: Salva a Ordem de Serviço isoladamente no banco (sem transação aberta)
        OrdemServico ordem = new OrdemServico(request.getCliente(), request.getIntegrationId());
        ordem.setStatus("PROCESSANDO_VULNERAVEL");
        ordem = ordemRepository.save(ordem);

        // Passo 2: Itera sobre os itens para salvar um a um
        if (request.getItens() != null) {
            for (ItemOrdemRequest itemReq : request.getItens()) {
                // INJEÇÃO DE FALHA 1: Quebra se o valor for negativo
                if (itemReq.getValor() != null && itemReq.getValor().compareTo(BigDecimal.ZERO) < 0) {
                    // Registra evidência forense de corrupção de dados
                    auditoriaService.registrar(
                            ipOrigem,
                            "/api/vulneravel/ordens",
                            "POST",
                            request.getIntegrationId(),
                            request.getCliente(),
                            "CENARIO_1_PARTIAL_COMMIT",
                            "CORRUPCAO_ESTADO_ORDEM_ORFA",
                            500,
                            "FALHA GRAVE: Ordem mestre ID=" + ordem.getId()
                                    + " gravada com sucesso, mas o item '" + itemReq.getDescricao()
                                    + "' falhou (valor negativo " + itemReq.getValor()
                                    + "). Ausência de @Transactional impediu Rollback!"
                    );

                    throw new InjecaoDeFalhaException(
                            "Injeção de Falha (Partial Commit): O item '" + itemReq.getDescricao() 
                            + "' possui valor negativo (" + itemReq.getValor() + "). "
                            + "Como NÃO há @Transactional, a Ordem ID=" + ordem.getId() 
                            + " foi salva e ficou ÓRFÃ no banco de dados!"
                    );
                }

                ItemOrdem item = new ItemOrdem(itemReq.getDescricao(), itemReq.getValor(), ordem);
                itemRepository.save(item);
                ordem.getItens().add(item);
            }
        }

        ordem.setStatus("CONCLUIDO_SEM_PROTECAO");
        ordem = ordemRepository.save(ordem);

        // Registra evidência de duplicidade descontrolada caso o integrationId já existisse
        if (jaExistia) {
            auditoriaService.registrar(
                    ipOrigem,
                    "/api/vulneravel/ordens",
                    "POST",
                    request.getIntegrationId(),
                    request.getCliente(),
                    "CENARIO_2_RETRY_ATTACK",
                    "DUPLICIDADE_GERADA",
                    201,
                    "RETRY SEM IDEMPOTÊNCIA: Nova ordem ID=" + ordem.getId()
                            + " inserida para a chave '" + request.getIntegrationId()
                            + "' que já existia no banco. Cliente cobrado novamente!"
            );
        } else {
            auditoriaService.registrar(
                    ipOrigem,
                    "/api/vulneravel/ordens",
                    "POST",
                    request.getIntegrationId(),
                    request.getCliente(),
                    "GRAVACAO_VULNERAVEL",
                    "SUCESSO_SEM_GARANTIAS",
                    201,
                    "Ordem ID=" + ordem.getId() + " gravada sem garantias de resiliência."
            );
        }

        return new OrdemServicoResponse(ordem, "Ordem gravada pela rota vulnerável (SEM garantia de atomicidade/idempotência).");
    }
}
