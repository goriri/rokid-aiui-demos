/**
 * Rokid Glasses AIUI Agent - GCP Live Translator Lifecycle
 */
export default {
  onLaunch() {
    console.log('[AIUI GCP App] Rokid GCP Live Translator Launched');
  },
  onShow() {
    console.log('[AIUI GCP App] Rokid GCP Live Translator Foreground');
  },
  onHide() {
    console.log('[AIUI GCP App] Rokid GCP Live Translator Background');
  },
  onError(error) {
    console.error('[AIUI GCP App] Runtime Error:', error);
  },
  globalData: {
    agentName: 'GCP Live Translator',
    version: '1.0.11',
    deviceType: 'RokidGlasses',
    viewport: {
      width: 480,
      height: 352
    }
  }
};
