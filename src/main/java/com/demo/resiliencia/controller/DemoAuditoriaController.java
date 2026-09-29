package com.demo.resiliencia.controller;

import com.demo.resiliencia.dto.OrdemServicoResponse;
import com.demo.resiliencia.model.AuditoriaTransacao;
import com.demo.resiliencia.model.OrdemServico;
import com.demo.resiliencia.repository.AuditoriaTransacaoRepository;
import com.demo.resiliencia.repository.ItemOrdemRepository;
import com.demo.resiliencia.repository.OrdemServicoRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/ordens")
public class DemoAuditoriaController {

    private final OrdemServicoRepository ordemRepository;
    private final ItemOrdemRepository itemRepository;
    private final AuditoriaTransacaoRepository auditoriaRepository;

    public DemoAuditoriaController(OrdemServicoRepository ordemRepository,
                                   ItemOrdemRepository itemRepository,
                                   AuditoriaTransacaoRepository auditoriaRepository) {
        this.ordemRepository = ordemRepository;
        this.itemRepository = itemRepository;
        this.auditoriaRepository = auditoriaRepository;
    }

    /**
     * Lista todas as ordens e itens salvos no banco.
     */
    @GetMapping
    public ResponseEntity<List<OrdemServicoResponse>> listarTodas() {
        List<OrdemServicoResponse> lista = ordemRepository.findAll().stream()
                .map(o -> new OrdemServicoResponse(o, "Registro consultado no banco"))
                .collect(Collectors.toList());
        return ResponseEntity.ok(lista);
    }

    /**
     * Mostra ordens órfãs (ordens sem itens) causadas por Partial Commit na rota vulnerável.
     */
    @GetMapping("/orfas")
    public ResponseEntity<Map<String, Object>> listarOrfas() {
        List<OrdemServico> orfas = ordemRepository.findOrdensOrfas();
        Map<String, Object> relatorio = new LinkedHashMap<>();
        relatorio.put("totalOrdensOrfas", orfas.size());
        relatorio.put("mensagem", orfas.isEmpty() 
            ? "Nenhuma ordem órfã detectada. O banco está íntegro." 
            : "ALERTA: Ordens órfãs encontradas! Criadas devido à ausência de @Transactional na Rota do Caos.");
        relatorio.put("ordens", orfas.stream()
                .map(o -> new OrdemServicoResponse(o, "Ordem Órfã (sem itens)"))
                .collect(Collectors.toList()));
        return ResponseEntity.ok(relatorio);
    }

    /**
     * Mostra ocorrências de um determinado integration_id para evidenciar duplicidades.
     */
    @GetMapping("/por-integration-id/{id}")
    public ResponseEntity<Map<String, Object>> buscarPorIntegrationId(@PathVariable String id) {
        List<OrdemServico> ordens = ordemRepository.findAllByIntegrationId(id);
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("integrationId", id);
        res.put("quantidadeRegistrosEncontrados", ordens.size());
        res.put("duplicidadeDetectada", ordens.size() > 1);
        res.put("ordens", ordens.stream()
                .map(o -> new OrdemServicoResponse(o, "Registro com integration_id=" + id))
                .collect(Collectors.toList()));
        return ResponseEntity.ok(res);
    }

    /**
     * Retorna o histórico forense e auditoria transacional gravada no PostgreSQL.
     */
    @GetMapping("/auditoria")
    public ResponseEntity<Map<String, Object>> listarAuditoria() {
        List<AuditoriaTransacao> registros = auditoriaRepository.findAllByOrderByDataHoraDesc();
        Map<String, Object> res = new LinkedHashMap<>();
        res.put("totalEventosRegistrados", registros.size());
        res.put("eventos", registros);
        return ResponseEntity.ok(res);
    }

    /**
     * Placar estatístico comparando Rota do Caos vs Rota Resiliente.
     */
    @GetMapping("/placar")
    public ResponseEntity<Map<String, Object>> obterPlacarResiliencia() {
        List<OrdemServico> todasOrdens = ordemRepository.findAll();
        List<OrdemServico> orfas = ordemRepository.findOrdensOrfas();

        long eventosCaos = auditoriaRepository.findAll().stream()
                .filter(a -> a.getRota() != null && a.getRota().contains("vulneravel"))
                .count();

        long eventosProtegidos = auditoriaRepository.findAll().stream()
                .filter(a -> a.getRota() != null && a.getRota().contains("protegido"))
                .count();

        long bloqueiosFailFast = auditoriaRepository.countByStatusExecucao("BLOQUEIO_PREVENTIVO_HTTP_400");
        long rollbacksExecutados = auditoriaRepository.countByStatusExecucao("ROLLBACK_AUTOMATICO_EXECUTADO");
        long deduplicacoesIdempotencia = auditoriaRepository.countByStatusExecucao("IDEMPOTENCIA_DEDUPLICADA");

        Map<String, Object> rotaCaos = new LinkedHashMap<>();
        rotaCaos.put("totalChamadas", eventosCaos);
        rotaCaos.put("ordensOrfasGeradas", orfas.size());
        rotaCaos.put("protecaoTransacional", "AUSENTE (Partial Commit ativo)");
        rotaCaos.put("toleranciaRetries", "NENHUMA (Duplicação descontrolada)");
        rotaCaos.put("diagnostico", orfas.isEmpty() ? "SEM_FALHAS_AINDA" : "BANCO_CORROMPIDO_INCONSISTENTE");

        Map<String, Object> rotaProtegida = new LinkedHashMap<>();
        rotaProtegida.put("totalChamadas", eventosProtegidos);
        rotaProtegida.put("bloqueiosFailFast", bloqueiosFailFast);
        rotaProtegida.put("rollbacksExecutados", rollbacksExecutados);
        rotaProtegida.put("deduplicacoesIdempotencia", deduplicacoesIdempotencia);
        rotaProtegida.put("ordensOrfasGeradas", 0);
        rotaProtegida.put("protecaoTransacional", "ATIVA (@Transactional ACID)");
        rotaProtegida.put("toleranciaRetries", "BLINDADA (Idempotency Key)");
        rotaProtegida.put("diagnostico", "BANCO_100_PORCENTO_INTEGRO");

        Map<String, Object> placar = new LinkedHashMap<>();
        placar.put("totalOrdensPersistidasNoBanco", todasOrdens.size());
        placar.put("rotaDoCaos", rotaCaos);
        placar.put("rotaResiliente", rotaProtegida);

        return ResponseEntity.ok(placar);
    }

    /**
     * Limpa as tabelas de itens, ordens e auditoria para reiniciar os testes da apresentação do zero.
     */
    @DeleteMapping("/reset")
    public ResponseEntity<Map<String, Object>> resetarBanco(
            @RequestParam(name = "limparAuditoria", defaultValue = "false") boolean limparAuditoria) {
        itemRepository.deleteAll();
        ordemRepository.deleteAll();

        if (limparAuditoria) {
            auditoriaRepository.deleteAll();
        }

        Map<String, Object> res = new LinkedHashMap<>();
        res.put("status", "SUCESSO");
        res.put("mensagem", "Tabelas de ordens e itens limpas com sucesso. " 
                + (limparAuditoria ? "Auditoria resetada." : "Histórico de auditoria preservado para fins periciais."));
        return ResponseEntity.ok(res);
    }
}
