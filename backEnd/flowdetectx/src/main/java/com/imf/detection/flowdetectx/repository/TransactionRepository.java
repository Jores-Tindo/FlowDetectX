package com.imf.detection.flowdetectx.repository;

import com.imf.detection.flowdetectx.model.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TransactionRepository extends JpaRepository<Transaction, Long> {
}
