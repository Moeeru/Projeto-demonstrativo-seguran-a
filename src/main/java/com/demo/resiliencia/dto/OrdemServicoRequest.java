package com.demo.resiliencia.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import java.util.ArrayList;
import java.util.List;

public class OrdemServicoRequest {

    @NotBlank(message = "O nome do cliente é obrigatório")
    private String cliente;

    @NotBlank(message = "O integration_id (chave externa de idempotência) é obrigatório")
    private String integrationId;

    @NotEmpty(message = "A ordem de serviço deve conter pelo menos um item")
    @Valid
    private List<ItemOrdemRequest> itens = new ArrayList<>();

    public OrdemServicoRequest() {
    }

    public OrdemServicoRequest(String cliente, String integrationId, List<ItemOrdemRequest> itens) {
        this.cliente = cliente;
        this.integrationId = integrationId;
        this.itens = itens;
    }

    public String getCliente() {
        return cliente;
    }

    public void setCliente(String cliente) {
        this.cliente = cliente;
    }

    public String getIntegrationId() {
        return integrationId;
    }

    public void setIntegrationId(String integrationId) {
        this.integrationId = integrationId;
    }

    public List<ItemOrdemRequest> getItens() {
        return itens;
    }

    public void setItens(List<ItemOrdemRequest> itens) {
        this.itens = itens;
    }
}
