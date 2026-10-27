# Modelos lógicos editáveis

Esta pasta contém os modelos lógicos produzidos no brModelo 3.2 e incorporados
ao repositório como a documentação visual oficial da arquitetura.

## Arquivos

| Arquivo | Escopo |
|---|---|
| `Schema-Venus-Logico.brM3` | Todas as tabelas do núcleo operacional `venus`. |
| `Schema-Venus_Audit-Logico.brM3` | `venus_audit.audit_logs`. |
| `Schema-Venus_RPA-Logico.brM3` | `venus_rpa.rpa_run`, `rpa_error`, `rpa_stage_product` e `rpa_stage_user`. |

## Pré-visualizações

As imagens em `previews/` são referências visuais exportadas do brModelo:

- `schema-venus.png`
- `schema-venus-audit.png`
- `schema-venus-rpa.png`

O desenho de `venus` é propositalmente grande e pode ficar ilegível quando
renderizado como uma única imagem. A fonte `.brM3` deve ser usada para zoom e
edição. Para conferência automatizada de campos e relacionamentos, use
`../database-logical-model.md` e `../database-logical-model.svg`.

## O que não possui `.brM3` próprio

`venus_bi` não possui tabelas físicas: suas estruturas são views analíticas
criadas em `sql/50_bi.sql`. `venus_optimization` possui apenas a tabela
`readme`; por isso ambos são descritos em `../ARQUITETURA.md` e no snapshot
gerado, sem um diagrama lógico independente.
