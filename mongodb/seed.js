(() => {
  const collection = db.getCollection('scan_sessions');
  const at = ISODate('2026-10-09T12:00:00Z');
  const samples = ['front', 'back', 'combined'].map((scanType, index) => {
    const scanId = `VS-DEMO-00${index + 1}`;
    const images = {};
    const ocr = {};
    const sides = scanType === 'combined' ? ['front', 'back'] : [scanType];
    for (const side of sides) {
      images[side] = {
        storage_provider: 'demo', public_id: `${scanId}/${side}`,
        secure_url: `https://example.invalid/${scanId}/${side}.jpg`,
        source_type: 'user_submission', captured_at: at
      };
      ocr[side] = {
        full_text: side === 'front' ? 'DEMO Sérum A' : 'DEMO BASE 1, DEMO ACTIVE A',
        extracted: side === 'front' ? {name: 'DEMO Sérum A'} : {
          ingredient_section_found: true,
          ingredients: [{
            position: NumberInt(1), raw_name: 'DEMO ACTIVE A', normalized_name: 'DEMO ACTIVE A',
            status: 'UNRESOLVED', match: {status: 'new', confidence: 0.0, postgres_ingredient_id: null},
            admin_decision: {action: 'pending', final_ingredient_id: null, create_unverified: false}
          }]
        }
      };
    }
    return {
      scan_id: scanId, status: 'pending_review',
      source: {type: 'ocr', channel: 'demo', submitted_at: at, user: {user_id: '900001'}},
      device: {platform: 'web', device_id: 'demo-device'},
      workflow: {scan_type: scanType, current_step: 'admin_review', started_at: at, finished_at: null},
      quality_check: {blur_score: 0.1, brightness: 0.8, background_ok: true, status: 'accepted', checked_at: at},
      images, ocr,
      interpretation: {product_match: {status: 'not_found', score: 0.0, postgres_product_id: null}},
      admin_review: {
        queue: {status: 'waiting', priority: 'normal', tags: ['demo']},
        assigned_admin_id: null, decision: 'pending', decided_at: null, rejection_reason: null,
        history: [{action: 'submitted', at, admin_id: null}]
      },
      postgres_projection: {ready_to_sync: false, validation_errors: ['Exemplo aguardando revisão']},
      postgres_sync: {
        status: 'not_started', idempotency_key: scanId, attempt: NumberInt(0),
        started_at: null, completed_at: null, error_code: null, error_message: null
      },
      created_at: at, updated_at: at
    };
  });
  printjson(collection.bulkWrite(samples.map(document => ({updateOne: {
    filter: {scan_id: document.scan_id}, update: {$setOnInsert: document}, upsert: true
  }}))));
})();
