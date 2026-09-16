package com.demo.resiliencia.controller;

import com.demo.resiliencia.dto.OrdemServicoRequest;
import com.demo.resiliencia.dto.OrdemServicoResponse;
import com.demo.resiliencia.service.VulneravelService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/vulneravel")
public class VulneravelController {

    private final VulneravelService vulneravelService;

    public VulneravelController(VulneravelService vulneravelService) {
        this.vulneravelService = vulneravelService;
    }

    /**
     * Endpoint do Caos:
     * - Sem @Valid (não faz Fail-Fast)
     * - Sem @Transactional (provoca Partial Commit e deixa ordens órfãs)
     * - Sem Idempotência (permite gravar o mesmo integration_id infinitamente)
     */
    @PostMapping("/ordens")
    public ResponseEntity<OrdemServicoResponse> criarOrdemVulneravel(@RequestBody OrdemServicoRequest request) {
        OrdemServicoResponse response = vulneravelService.processarOrdemVulneravel(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
}
