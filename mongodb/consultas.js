(() => {
  const collection = db.getCollection('scan_sessions');
  print('Fila de revisão, mais antigos primeiro:');
  printjson(collection.find({status: 'pending_review'})
    .sort({created_at: 1}).limit(20).toArray());
  print('Scans do usuário 900001:');
  printjson(collection.find({'source.user.user_id': '900001'})
    .sort({created_at: -1}).limit(20).toArray());
  print('Aprovados aguardando sincronização:');
  printjson(collection.find({
    'admin_review.decision': 'approved', 'postgres_projection.ready_to_sync': true,
    'postgres_sync.status': {$in: ['pending', 'failed']}
  }).sort({updated_at: 1}).limit(20).toArray());
})();
