package com.demo.resiliencia.model;

import com.fasterxml.jackson.annotation.JsonManagedReference;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "ordens_servico")
public class OrdemServico {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String cliente;

    @Column(name = "integration_id")
    private String integrationId;

    @Column(nullable = false)
    private String status;

    @Column(name = "criado_em", nullable = false)
    private LocalDateTime criadoEm;

    @OneToMany(mappedBy = "ordem", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    @JsonManagedReference
    private List<ItemOrdem> itens = new ArrayList<>();

    public OrdemServico() {
        this.criadoEm = LocalDateTime.now();
        this.status = "CRIADO";
    }

    public OrdemServico(String cliente, String integrationId) {
        this();
        this.cliente = cliente;
        this.integrationId = integrationId;
    }

    public void adicionarItem(ItemOrdem item) {
        itens.add(item);
        item.setOrdem(this);
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
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

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getCriadoEm() {
        return criadoEm;
    }

    public void setCriadoEm(LocalDateTime criadoEm) {
        this.criadoEm = criadoEm;
    }

    public List<ItemOrdem> getItens() {
        return itens;
    }

    public void setItens(List<ItemOrdem> itens) {
        this.itens = itens;
    }
}
