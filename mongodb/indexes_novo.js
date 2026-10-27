// Execute após validation_novo.js, na mesma base mongosh.
(() => {
  const collection = db.getCollection('scan_sessions');
  collection.createIndex({scan_id: 1}, {unique: true});
  collection.createIndex({status: 1, created_at: -1});
  collection.createIndex({'postgres_sync.status': 1, updated_at: -1});
  collection.createIndex({'admin_review.assigned_admin_id': 1, status: 1});
  collection.createIndex({'source.user.user_id': 1, created_at: -1});
  collection.createIndex({'interpretation.product_match.postgres_product_id': 1});
  printjson(collection.getIndexes());
})();
