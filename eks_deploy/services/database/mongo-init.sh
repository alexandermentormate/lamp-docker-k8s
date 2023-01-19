set -e

mongo <<EOF

db.getSiblingDB('admin').createUser(
  {
    user: '$MONGODB_USERNAME',
    pwd: '$MONGODB_PASSWORD',
    roles: [ { role: 'readWrite', db: 'flaskdb' },]
  }
);

db = db.getSiblingDB('flaskdb');
db.createCollection('books');

EOF