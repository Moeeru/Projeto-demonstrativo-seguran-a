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

    public VulneravelService(OrdemServicoRepository ordemRepository, ItemOrdemRepository itemRepository) {
        this.ordemRepository = ordemRepository;
        this.itemRepository = itemRepository;
    }

    /**
     * ROTA DO CAOS:
     * 1. NÃO tem @Transactional (sem atomicidade).
     * 2. NÃO verifica integration_id (sem idempotência, aceita duplicatas).
     * 3. Injeção de Falha (Partial Commit): ao encontrar item com valor negativo, interrompe a execução
     *    após já ter persistido a OrdemServico no banco, gerando registro órfão.
     */
    public OrdemServicoResponse processarOrdemVulneravel(OrdemServicoRequest request) {
        // Passo 1: Salva a Ordem de Serviço isoladamente no banco (sem transação aberta)
        OrdemServico ordem = new OrdemServico(request.getCliente(), request.getIntegrationId());
        ordem.setStatus("PROCESSANDO_VULNERAVEL");
        ordem = ordemRepository.save(ordem);

        // Passo 2: Itera sobre os itens para salvar um a um
        if (request.getItens() != null) {
            for (ItemOrdemRequest itemReq : request.getItens()) {
                // INJEÇÃO DE FALHA 1: Quebra se o valor for negativo
                if (itemReq.getValor() != null && itemReq.getValor().compareTo(BigDecimal.ZERO) < 0) {
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

        return new OrdemServicoResponse(ordem, "Ordem gravada pela rota vulnerável (SEM garantia de atomicidade/idempotência).");
    }
}
