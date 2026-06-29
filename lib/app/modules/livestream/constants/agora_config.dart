

// Agora App Configuration
const String AGORA_APP_ID = 'a350e619e53b4fc8babba97b3b9fd7a0';
const String AGORA_APP_CERTIFICATE = '71288c26f81a4e99b807c701422d8918';

// Token expiration time (in seconds)
const int TOKEN_EXPIRATION_TIME = 3600; // 1 hour

// Temporary token for fallback (generate this from Agora Console)
const String TEMP_TOKEN = '006d0015737a05546b6be82f188951f5772IABnxBWRKxxx...'; // Replace with a valid temporary token

// Channel defaults
const String DEFAULT_CHANNEL_NAME = 'Sagor Hossain';

// Token server URL (if you're using one)
const String AGORA_TOKEN_SERVER_URL = 'https://agora-token-service-production.up.railway.app';

// For temporary testing without token (using App ID only mode)
class AgoraConfig {
  static const String appId = 'a350e619e53b4fc8babba97b3b9fd7a0';
  static const bool enableToken = false;  // Set to false for testing
  static const int uid = 0;
  static const int tokenRole = 1;  // 1 for publisher/host
  static const int tokenExpireTime = 3600;  // 1 hour in seconds
} 
