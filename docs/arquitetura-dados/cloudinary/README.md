# Cloudinary e mídia

O Cloudinary armazena os binários de imagem fora do PostgreSQL. O banco mantém
`venus.media_assets` como registro canônico de `public_id`, URL segura,
dimensões, formato, finalidade, status e vínculo com usuário, produto ou lista.

Fluxo recomendado:

1. backend autentica e autoriza a operação;
2. backend gera uma assinatura curta;
3. cliente envia a imagem diretamente ao Cloudinary;
4. backend valida a resposta e registra os metadados em `media_assets`;
5. views `v_user_avatars`, `v_product_photos` e `v_user_list_covers` expõem as
   leituras da aplicação.

O segredo `CLOUDINARY_API_SECRET` nunca deve ir para web/mobile, logs ou
payloads. O contrato detalhado está em [`../../../CLOUDINARY_API.md`](../../../CLOUDINARY_API.md)
e o modelo SQL em [`../../../sql/05_cloudinary_images.sql`](../../../sql/05_cloudinary_images.sql).
