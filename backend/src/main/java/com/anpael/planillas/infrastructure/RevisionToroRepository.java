package com.anpael.planillas.infrastructure;

import org.springframework.data.jpa.repository.JpaRepository;

import com.anpael.planillas.domain.RevisionToro;

public interface RevisionToroRepository extends JpaRepository<RevisionToro, Integer> {
}
