// FILE INI HANYA UNTUK TESTING VULNERABILITY DETECTION
// JANGAN GUNAKAN DALAM PRODUCTION!

const crypto = require('crypto');
const fs = require('fs');

// Vulnerable patterns yang mungkin terdeteksi oleh static analysis
class VulnerablePatterns {
  
  // 1. Weak cryptography
  weakEncryption(data) {
    return crypto.createHash('md5').update(data).digest('hex');
  }
  
  // 2. Command injection vulnerability
  executeCommand(userInput) {
    const { exec } = require('child_process');
    return exec(`echo ${userInput}`); // Dangerous!
  }
  
  // 3. Path traversal vulnerability
  readFile(filename) {
    return fs.readFileSync(`./uploads/${filename}`, 'utf8');
  }
  
  // 4. SQL injection (simulated)
  queryDatabase(userId) {
    const query = `SELECT * FROM users WHERE id = ${userId}`;
    return query; // Dangerous concatenation
  }
  
  // 5. XSS vulnerability
  renderUserContent(userContent) {
    document.innerHTML = userContent; // Dangerous!
  }
  
  // 6. Insecure random
  generateToken() {
    return Math.random().toString(36).substring(7);
  }
}

module.exports = VulnerablePatterns;