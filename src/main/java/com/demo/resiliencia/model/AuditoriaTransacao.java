package com.demo.resiliencia.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "auditoria_transacional")
public class AuditoriaTransacao {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "data_hora", nullable = false)
    private LocalDateTime dataHora;

    @Column(name = "ip_origem")
    private String ipOrigem;

    @Column(nullable = false)
    private String rota;

    @Column(name = "metodo_http", nullable = false)
    private String metodoHttp;

    @Column(name = "integration_id")
    private String integrationId;

    private String cliente;

    @Column(name = "tipo_cenario", nullable = false)
    private String tipoCenario;

    @Column(name = "status_execucao", nullable = false)
    private String statusExecucao;

    @Column(name = "codigo_http", nullable = false)
    private Integer codigoHttp;

    @Column(name = "detalhes_tecnicos", length = 1000)
    private String detalhesTecnicos;

    public AuditoriaTransacao() {
        this.dataHora = LocalDateTime.now();
    }

    public AuditoriaTransacao(String ipOrigem, String rota, String metodoHttp, String integrationId,
                              String cliente, String tipoCenario, String statusExecucao,
                              Integer codigoHttp, String detalhesTecnicos) {
        this.dataHora = LocalDateTime.now();
        this.ipOrigem = (ipOrigem != null && !ipOrigem.isBlank()) ? ipOrigem : "127.0.0.1";
        this.rota = rota;
        this.metodoHttp = metodoHttp;
        this.integrationId = integrationId;
        this.cliente = cliente;
        this.tipoCenario = tipoCenario;
        this.statusExecucao = statusExecucao;
        this.codigoHttp = codigoHttp;
        this.detalhesTecnicos = detalhesTecnicos;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public LocalDateTime getDataHora() {
        return dataHora;
    }

    public void setDataHora(LocalDateTime dataHora) {
        this.dataHora = dataHora;
    }

    public String getIpOrigem() {
        return ipOrigem;
    }

    public void setIpOrigem(String ipOrigem) {
        this.ipOrigem = ipOrigem;
    }

    public String getRota() {
        return rota;
    }

    public void setRota(String rota) {
        this.rota = rota;
    }

    public String getMetodoHttp() {
        return metodoHttp;
    }

    public void setMetodoHttp(String metodoHttp) {
        this.metodoHttp = metodoHttp;
    }

    public String getIntegrationId() {
        return integrationId;
    }

    public void setIntegrationId(String integrationId) {
        this.integrationId = integrationId;
    }

    public String getCliente() {
        return cliente;
    }

    public void setCliente(String cliente) {
        this.cliente = cliente;
    }

    public String getTipoCenario() {
        return tipoCenario;
    }

    public void setTipoCenario(String tipoCenario) {
        this.tipoCenario = tipoCenario;
    }

    public String getStatusExecucao() {
        return statusExecucao;
    }

    public void setStatusExecucao(String statusExecucao) {
        this.statusExecucao = statusExecucao;
    }

    public Integer getCodigoHttp() {
        return codigoHttp;
    }

    public void setCodigoHttp(Integer codigoHttp) {
        this.codigoHttp = codigoHttp;
    }

    public String getDetalhesTecnicos() {
        return detalhesTecnicos;
    }

    public void setDetalhesTecnicos(String detalhesTecnicos) {
        this.detalhesTecnicos = detalhesTecnicos;
    }
}
