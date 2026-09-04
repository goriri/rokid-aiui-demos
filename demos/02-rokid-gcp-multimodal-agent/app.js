/**
 * Rokid Glasses AIUI Agent - Google Cloud AI Multimodal Agent Lifecycle
 */
export default {
  onLaunch() {
    console.log('[AIUI GCP App] Rokid GCP Multimodal Agent Launched');
  },
  onShow() {
    console.log('[AIUI GCP App] Rokid GCP Multimodal Agent Foreground');
  },
  onHide() {
    console.log('[AIUI GCP App] Rokid GCP Multimodal Agent Background');
  },
  onError(error) {
    console.error('[AIUI GCP App] Runtime Error:', error);
  },
  globalData: {
    agentName: 'GCP 多模态眼镜助理',
    version: '1.0.0',
    deviceType: 'RokidGlasses',
    viewport: {
      width: 480,
      height: 352
    }
  }
};
