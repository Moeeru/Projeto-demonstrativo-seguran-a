package com.demo.resiliencia.dto;

import com.demo.resiliencia.model.OrdemServico;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

public class OrdemServicoResponse {
    private Long id;
    private String cliente;
    private String integrationId;
    private String status;
    private LocalDateTime criadoEm;
    private int quantidadeItens;
    private List<ItemOrdemResponse> itens;
    private String mensagem;

    public OrdemServicoResponse() {}

    public OrdemServicoResponse(OrdemServico ordem, String mensagem) {
        this.id = ordem.getId();
        this.cliente = ordem.getCliente();
        this.integrationId = ordem.getIntegrationId();
        this.status = ordem.getStatus();
        this.criadoEm = ordem.getCriadoEm();
        this.itens = ordem.getItens() != null 
                ? ordem.getItens().stream().map(ItemOrdemResponse::new).collect(Collectors.toList())
                : List.of();
        this.quantidadeItens = this.itens.size();
        this.mensagem = mensagem;
    }

    public Long getId() { return id; }
    public String getCliente() { return cliente; }
    public String getIntegrationId() { return integrationId; }
    public String getStatus() { return status; }
    public LocalDateTime getCriadoEm() { return criadoEm; }
    public int getQuantidadeItens() { return quantidadeItens; }
    public List<ItemOrdemResponse> getItens() { return itens; }
    public String getMensagem() { return mensagem; }
}
