# Venus + Cloudinary — integração segura para API, Web e Mobile

## 0. Fonte única de verdade

No V7, `venus.media_assets` é a única fonte de verdade de mídia. `users` e `product_versions` não possuem colunas Cloudinary duplicadas.

## 1. Arquitetura definitiva

Os binários ficam no Cloudinary. O PostgreSQL guarda somente metadados e o estado de vínculo do asset em `venus.media_assets`.

```text
Web / Mobile
    |
    | POST /api/v1/media/signature
    v
Venus API
    | autentica + autoriza + define public_id/folder
    | gera assinatura curta usando API_SECRET
    v
Cliente Web/Mobile
    |
    | multipart upload assinado
    v
Cloudinary Upload API
    |
    | resposta (asset_id/public_id/version/secure_url/signature)
    v
Venus API
    | valida signature da resposta
    | persiste metadata
    v
PostgreSQL venus.media_assets
```

O Cloudinary recomenda assinatura gerada no servidor e nunca expor o API secret ao cliente. O upload assinado usa `timestamp` e os parâmetros mutáveis do POST; a resposta também pode ser validada por assinatura antes do armazenamento dos metadados.

## 2. Modelo PostgreSQL

`venus.media_assets` é o registro canônico. Cada linha é exatamente um asset de imagem e pode pertencer a um usuário (avatar) ou a uma versão de produto (foto).

Garantias:

- `public_id` único por provider.
- avatar: no máximo um asset `pending/active` por usuário.
- foto de produto: múltiplas fotos por versão, ordenadas por `sort_order`.
- exatamente um owner (`fk_user_id` XOR `fk_product_version_id`).
- `resource_type='image'`.
- `delivery_type` pode ser `upload` ou `authenticated`.
- `status` permite controlar ciclo de vida sem apagar histórico imediatamente.

Não existem colunas `users.avatar_*` nem `product_versions.photo_*` no V7. `venus.media_assets` é a única fonte de verdade de mídia; as views de consumo expõem os dados necessários à API.

## 3. Variáveis `.env`

```env
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...
CLOUDINARY_SIGNATURE_ALGORITHM=sha256
CLOUDINARY_SIGNED_UPLOAD_PRESET=venus_signed_images
CLOUDINARY_IMAGE_FOLDER=venus
CLOUDINARY_UPLOAD_MAX_BYTES=10485760
CLOUDINARY_ALLOWED_FORMATS=jpg,jpeg,png,webp
CLOUDINARY_SIGNED_UPLOAD_TTL_SECONDS=3600
```

O `.env` real nunca deve ser versionado. O `API_SECRET` é backend-only. O upload preset assinado pode ser usado para centralizar limites e regras do Cloudinary.

Cloudinary permite configurar presets assinados/unsigned e aplicar limitações de formato/tamanho no preset. Para produção, uploads assinados dão uma barreira de segurança melhor porque o cliente não conhece o segredo.

## 4. Configuração recomendada no Cloudinary Console

Crie um **Signed Upload Preset** chamado, por exemplo, `venus_signed_images` e configure no preset:

- signing mode: Signed;
- resource type: Image;
- formatos: JPG, JPEG, PNG, WebP;
- limite de tamanho compatível com `CLOUDINARY_UPLOAD_MAX_BYTES`;
- `use_filename` desativado;
- `unique_filename` conforme a política da conta, sem permitir que o cliente escolha a identidade canônica;
- pasta/asset folder conforme a organização desejada;
- transformações de entrada para normalizar dimensões, se desejado.

O `public_id` usado pelo Venus é gerado pelo backend, não recebido livremente do cliente.

## 5. Endpoint para web/mobile

Contrato sugerido:

`POST /api/v1/media/signature`

Request:

```json
{"purpose":"avatar"}
```

ou:

```json
{"purpose":"product_photo","product_version_id":987}
```

O backend deve obter `user_id` do token autenticado, e não confiar em um `user_id` enviado pelo cliente. Para fotos de produto, deve verificar se o usuário/serviço possui autorização sobre a versão do produto.

Response pública:

```json
{
  "cloud_name": "...",
  "api_key": "...",
  "timestamp": 1234567890,
  "signature": "...",
  "signature_algorithm": "sha256",
  "folder": "venus/users",
  "public_id": "venus/users/123/avatar",
  "overwrite": true,
  "resource_type": "image",
  "upload_preset": "venus_signed_images",
  "expires_in": 3600
}
```

O `api_secret` nunca aparece nesse JSON.

## 6. Upload no cliente

Web e mobile podem usar o upload direto ao endpoint Cloudinary com os parâmetros assinados. O upload do arquivo não precisa passar pelo servidor Venus, reduzindo carga e latência. Cloudinary documenta essa abordagem para browser/mobile com uploads assinados.

O cliente deve enviar exatamente os campos que foram assinados. Não altere `public_id`, `folder`, `timestamp`, `overwrite` ou `upload_preset` depois que a assinatura for gerada.

## 7. Callback após upload

Depois do upload, o cliente envia a resposta do Cloudinary à API Venus, ou a aplicação usa um webhook/callback do Cloudinary.

Antes de persistir:

1. valide a assinatura da resposta;
2. confirme `resource_type='image'`;
3. confirme que `public_id` pertence ao namespace esperado (`venus/users/...` ou `venus/products/...`);
4. confirme que o asset pertence ao owner esperado;
5. grave os metadados em `venus.media_assets`;
6. marque `status='active'` somente após as validações.

A resposta do upload inclui `public_id`, versão, URLs e dados como dimensões/formato; esses dados podem ser armazenados como metadados.

## 8. Delete/replace

`cloudinary_service.delete_asset()` é backend-only.

Para avatar:

- usar o `public_id` canônico do registro;
- upload de substituição pode usar `overwrite=true` somente em operação autorizada;
- atualizar o registro/estado de forma transacional;
- invalidar cache no Cloudinary quando necessário.

Para foto de produto:

- gerar novo `public_id` UUID no backend;
- não permitir que o cliente escolha o caminho;
- marcar o asset antigo como `deleted` após a exclusão confirmada.

## 9. Entrega Web/Mobile

Para imagens públicas, a API pode devolver `secure_url` ou derivá-la pelo `public_id`. O Cloudinary permite transformações de entrega, então o cliente pode consumir variantes otimizadas sem armazenar novas cópias no PostgreSQL.

Para conteúdo privado, não retorne uma URL pública permanente: use delivery type `authenticated` e URLs assinadas/time-limited conforme a política de acesso.

## 10. Limites e segurança

A API deve impor autenticação e autorização antes da assinatura. Limite tamanho e formatos no backend e no preset. Nunca aceite caminhos arbitrários, `public_id` livre ou transformações administrativas do cliente.

Uploads unsigned são possíveis, mas o nome do preset fica exposto no cliente e esse mecanismo é menos seguro; se um preset unsigned for usado, ele deve ser estritamente limitado e rotacionado em caso de abuso. Para o Venus, o padrão de produção recomendado é signed upload.

## 11. Checklist de implementação

Ao implementar o endpoint `/api/v1/media/signature` e o fluxo de callback, confirme:

- [ ] o `user_id` usado na assinatura vem do token autenticado, nunca do corpo da requisição;
- [ ] para `product_photo`, a autorização sobre `product_version_id` foi verificada antes de gerar a assinatura;
- [ ] `public_id` é gerado no backend, seguindo o namespace `venus/users/...` ou `venus/products/...`;
- [ ] a assinatura da resposta do Cloudinary é validada antes de qualquer `INSERT`/`UPDATE` em `venus.media_assets`;
- [ ] o registro só é marcado como `active` após essa validação;
- [ ] `CLOUDINARY_API_SECRET` não aparece em nenhum payload devolvido ao cliente nem em logs;
- [ ] limites de tamanho/formato são reforçados tanto no preset do Cloudinary quanto no backend.

## Ver também

- `CLOUDINARY_IMAGES.md` — visão resumida do modelo canônico de imagens e do ciclo de vida do asset.
- `README.md` — seção "Imagens / Cloudinary" com o resumo da arquitetura no contexto geral do pacote.
- `.env.example` — modelo das variáveis `CLOUDINARY_*` consumidas por `cloudinary_service.py`.
