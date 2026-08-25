package com.anpael.shared.audit;

import java.time.OffsetDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.MappedSuperclass;
import lombok.Getter;
import lombok.Setter;
import org.springframework.data.annotation.CreatedBy;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedBy;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

/**
 * Auditoria basica: quien creo cada fila y cuando, quien la modifico por
 * ultima vez y cuando.
 *
 * DOS COSAS QUE NO SON LO MISMO Y CONVIENE NO CONFUNDIR:
 *
 *   creadoEn      -> cuando se CARGO el dato en el sistema
 *   fechaEvento   -> cuando OCURRIO el hecho en el campo
 *
 * Un tacto del 9 de marzo cargado el 20 de agosto tiene esas dos fechas
 * distintas. Si se usa una sola, los reportes mienten: o el trabajo aparece
 * hecho en agosto, o parece que el sistema se uso en marzo. Por eso
 * fechaEvento vive en cada entidad de negocio y NO aca.
 *
 * Nota: las tablas que vienen de la migracion del Excel no tienen estas
 * columnas. Se agregan por migracion a medida que cada modulo las necesita,
 * no todas de una vez.
 */
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
@Getter
@Setter
public abstract class AuditableEntity {

    @CreatedDate
    @Column(name = "creado_en", updatable = false)
    private OffsetDateTime creadoEn;

    @CreatedBy
    @Column(name = "creado_por", updatable = false)
    private String creadoPor;

    @LastModifiedDate
    @Column(name = "modificado_en")
    private OffsetDateTime modificadoEn;

    @LastModifiedBy
    @Column(name = "modificado_por")
    private String modificadoPor;
}
