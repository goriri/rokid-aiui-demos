/**
 * Rokid Glasses AIUI Agent - Global Application Lifecycle
 */
export default {
  onLaunch() {
    console.log('[AIUI App] Rokid Glasses AR Copilot Launched');
  },
  onShow() {
    console.log('[AIUI App] Rokid Glasses AR Copilot Foreground');
  },
  onHide() {
    console.log('[AIUI App] Rokid Glasses AR Copilot Background');
  },
  onError(error) {
    console.error('[AIUI App] Runtime Error:', error);
  },
  globalData: {
    agentName: 'AR 随身眼脑助手',
    version: '1.0.0',
    deviceType: 'RokidGlasses',
    viewport: {
      width: 480,
      height: 352
    }
  }
};
