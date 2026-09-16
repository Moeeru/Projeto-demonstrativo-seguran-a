package com.demo.resiliencia.dto;

import com.demo.resiliencia.model.ItemOrdem;
import java.math.BigDecimal;

public class ItemOrdemResponse {
    private Long id;
    private String descricao;
    private BigDecimal valor;

    public ItemOrdemResponse() {}

    public ItemOrdemResponse(ItemOrdem item) {
        this.id = item.getId();
        this.descricao = item.getDescricao();
        this.valor = item.getValor();
    }

    public Long getId() { return id; }
    public String getDescricao() { return descricao; }
    public BigDecimal getValor() { return valor; }
}
