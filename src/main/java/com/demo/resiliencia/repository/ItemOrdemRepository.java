package com.demo.resiliencia.repository;

import com.demo.resiliencia.model.ItemOrdem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ItemOrdemRepository extends JpaRepository<ItemOrdem, Long> {
    List<ItemOrdem> findByOrdemId(Long ordemId);
}
