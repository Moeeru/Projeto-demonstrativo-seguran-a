package com.demo.resiliencia.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

public class ItemOrdemRequest {

    @NotBlank(message = "A descrição do item é obrigatória")
    private String descricao;

    @NotNull(message = "O valor do item é obrigatório")
    @DecimalMin(value = "0.00", message = "O valor do item não pode ser negativo (Fail-Fast: Fail fast antes de processar)")
    private BigDecimal valor;

    public ItemOrdemRequest() {
    }

    public ItemOrdemRequest(String descricao, BigDecimal valor) {
        this.descricao = descricao;
        this.valor = valor;
    }

    public String getDescricao() {
        return descricao;
    }

    public void setDescricao(String descricao) {
        this.descricao = descricao;
    }

    public BigDecimal getValor() {
        return valor;
    }

    public void setValor(BigDecimal valor) {
        this.valor = valor;
    }
}
