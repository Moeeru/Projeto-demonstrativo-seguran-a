package com.demo.resiliencia;

import com.demo.resiliencia.dto.ItemOrdemRequest;
import com.demo.resiliencia.dto.OrdemServicoRequest;
import com.demo.resiliencia.dto.OrdemServicoResponse;
import com.demo.resiliencia.exception.InjecaoDeFalhaException;
import com.demo.resiliencia.model.OrdemServico;
import com.demo.resiliencia.repository.ItemOrdemRepository;
import com.demo.resiliencia.repository.OrdemServicoRepository;
import com.demo.resiliencia.service.ProtegidoService;
import com.demo.resiliencia.service.VulneravelService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ResilienciaApplicationTests {

    @Mock
    private OrdemServicoRepository ordemRepository;

    @Mock
    private ItemOrdemRepository itemRepository;

    @InjectMocks
    private VulneravelService vulneravelService;

    @InjectMocks
    private ProtegidoService protegidoService;

    private OrdemServicoRequest requestValido;
    private OrdemServicoRequest requestComItemNegativo;

    @BeforeEach
    void setUp() {
        requestValido = new OrdemServicoRequest(
                "Cliente Teste",
                "INT-123",
                List.of(new ItemOrdemRequest("Item A", new BigDecimal("100.00")))
        );

        requestComItemNegativo = new OrdemServicoRequest(
                "Cliente Teste",
                "INT-999",
                List.of(
                        new ItemOrdemRequest("Item OK", new BigDecimal("100.00")),
                        new ItemOrdemRequest("Item Negativo", new BigDecimal("-50.00"))
                )
        );
    }

    @Test
    @DisplayName("VulneravelService: Deve persistir ordem mas quebrar nos itens ao encontrar valor negativo (Partial Commit)")
    void deveQuebrarComPartialCommitNoVulneravel() {
        OrdemServico ordemSimulada = new OrdemServico("Cliente Teste", "INT-999");
        ordemSimulada.setId(1L);
        when(ordemRepository.save(any(OrdemServico.class))).thenReturn(ordemSimulada);

        // Ao processar o item negativo, deve estourar InjecaoDeFalhaException
        InjecaoDeFalhaException ex = assertThrows(InjecaoDeFalhaException.class, () -> {
            vulneravelService.processarOrdemVulneravel(requestComItemNegativo);
        });

        assertTrue(ex.getMessage().contains("Partial Commit"));
        // Comprova que a ordem foi salva antes do erro
        verify(ordemRepository, atLeastOnce()).save(any(OrdemServico.class));
    }

    @Test
    @DisplayName("ProtegidoService: Idempotência deve retornar registro existente sem criar duplicata")
    void deveAtivarIdempotenciaQuandoJaExistir() {
        OrdemServico ordemExistente = new OrdemServico("Cliente Teste", "INT-123");
        ordemExistente.setId(42L);

        when(ordemRepository.findByIntegrationId("INT-123")).thenReturn(Optional.of(ordemExistente));

        OrdemServicoResponse response = protegidoService.processarOrdemProtegida(requestValido, false);

        assertNotNull(response);
        assertEquals(42L, response.getId());
        assertTrue(response.getMensagem().contains("IDEMPOTÊNCIA"));
        verify(ordemRepository, never()).save(any(OrdemServico.class));
    }

    @Test
    @DisplayName("ProtegidoService: Deve gravar com sucesso quando ordem for inédita")
    void deveGravarComSucessoOrdemProtegida() {
        when(ordemRepository.findByIntegrationId("INT-123")).thenReturn(Optional.empty());

        OrdemServico ordemNova = new OrdemServico("Cliente Teste", "INT-123");
        ordemNova.setId(10L);
        when(ordemRepository.save(any(OrdemServico.class))).thenReturn(ordemNova);

        OrdemServicoResponse response = protegidoService.processarOrdemProtegida(requestValido, false);

        assertNotNull(response);
        assertEquals(10L, response.getId());
        verify(ordemRepository, times(1)).save(any(OrdemServico.class));
        verify(itemRepository, times(1)).save(any());
    }
}
