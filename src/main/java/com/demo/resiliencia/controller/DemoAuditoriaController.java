package com.demo.resiliencia.controller;

import com.demo.resiliencia.dto.OrdemServicoResponse;
import com.demo.resiliencia.model.OrdemServico;
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

    public DemoAuditoriaController(OrdemServicoRepository ordemRepository, ItemOrdemRepository itemRepository) {
        this.ordemRepository = ordemRepository;
        this.itemRepository = itemRepository;
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
     * Limpa as tabelas de itens e ordens para reiniciar os testes da apresentação do zero.
     */
    @DeleteMapping("/reset")
    public ResponseEntity<Map<String, Object>> resetarBanco() {
        itemRepository.deleteAll();
        ordemRepository.deleteAll();

        Map<String, Object> res = new LinkedHashMap<>();
        res.put("status", "SUCESSO");
        res.put("mensagem", "Banco de dados resetado com sucesso. Pronto para nova rodada de testes!");
        return ResponseEntity.ok(res);
    }
}
