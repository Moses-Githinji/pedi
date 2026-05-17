const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Export all function modules here
// Example: exports.vibeMeter = require('./src/vibeMeter');

exports.helloPedi = functions.https.onRequest((request, response) => {
  functions.logger.info("Hello Pedi App!", {structuredData: true});
  response.send("Hello from Pedi Backend!");
});
