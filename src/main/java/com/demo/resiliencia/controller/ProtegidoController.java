package com.demo.resiliencia.controller;

import com.demo.resiliencia.dto.OrdemServicoRequest;
import com.demo.resiliencia.dto.OrdemServicoResponse;
import com.demo.resiliencia.service.ProtegidoService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/protegido")
public class ProtegidoController {

    private final ProtegidoService protegidoService;

    public ProtegidoController(ProtegidoService protegidoService) {
        this.protegidoService = protegidoService;
    }

    /**
     * Endpoint Resiliente:
     * - Proteção 3: Fail-Fast com @Valid no RequestBody (bloqueia payloads ruins antes de tocarem na regra de negócio).
     * - Proteção 1: Atomicidade com @Transactional (se a falha ocorrer, rollback total de tudo).
     * - Proteção 2: Idempotência por integration_id (evita duplicidade em retentativas).
     * 
     * O parâmetro opcional ?simularFalhaTransacao=true permite forçar uma exceção de runtime no meio
     * da transação para demonstrar o Rollback Atômico mesmo quando o payload atende ao formato dos DTOs.
     */
    @PostMapping("/ordens")
    public ResponseEntity<OrdemServicoResponse> criarOrdemProtegida(
            @Valid @RequestBody OrdemServicoRequest request,
            @RequestParam(name = "simularFalhaTransacao", defaultValue = "false") boolean simularFalhaTransacao) {

        OrdemServicoResponse response = protegidoService.processarOrdemProtegida(request, simularFalhaTransacao);

        // Se for idempotência (já existia), retorna 200 OK. Se foi criado agora, retorna 201 CREATED.
        if (response.getMensagem() != null && response.getMensagem().contains("IDEMPOTÊNCIA")) {
            return ResponseEntity.ok(response);
        }

        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
}
