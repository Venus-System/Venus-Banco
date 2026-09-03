# Venus + Cloudinary — modelo canônico de imagens

## Regra principal

`venus.media_assets` é a **única fonte de verdade** para imagens do Venus. Não existem colunas Cloudinary em `users` ou `product_versions`.

```text
users ----------------------┐
                            │ FK
product_versions -----------┼----> venus.media_assets ----> Cloudinary
                            │
                            └---- metadados, vínculo, estado
```

O PostgreSQL guarda vínculo, identidade e metadados. O binário vive no Cloudinary.

## Tipos

- `avatar`: `fk_user_id` obrigatório; `fk_product_version_id` nulo.
- `product_photo`: `fk_product_version_id` obrigatório; `fk_user_id` nulo.

## Identidade

- `public_id`: identidade operacional controlada pelo backend.
- `asset_id`: identificador imutável do Cloudinary, quando disponível.
- `secure_url`: URL HTTPS de entrega; é metadado, não a identidade.

## Ciclo de vida

`pending -> active`, `pending -> failed` e `active -> deleted`.

Isso permite que a API só marque um asset como ativo depois de validar a resposta do Cloudinary.

## Web/Mobile

O cliente pede autorização à API. A API autentica, autoriza, define `public_id`/folder e gera uma assinatura curta. O cliente envia o binário diretamente ao Cloudinary e nunca recebe o `CLOUDINARY_API_SECRET`.

Depois do upload, a API valida a resposta e grava `venus.media_assets`.

## Relação com o schema

`venus.media_assets` é criada e mantida por `sql/05_cloudinary_images.sql`, executado pelo `pipeline.py` durante o bootstrap. As colunas de conveniência `avatar_*`/`photo_*` que existiam em versões anteriores (V6) foram removidas do modelo atual (V7) — ver `PACKAGE_CHANGELOG_V7.md` para o histórico dessa mudança.

## Este documento vs. `CLOUDINARY_API.md`

Este arquivo descreve o **modelo de dados** canônico de imagens (tabela, tipos, ciclo de vida). Para o **contrato de API** completo — endpoint de assinatura, formato de request/response, checklist de segurança e configuração do preset no Cloudinary Console — consulte `CLOUDINARY_API.md`.
