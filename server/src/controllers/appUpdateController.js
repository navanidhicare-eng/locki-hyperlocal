const fs = require('fs');
const path = require('path');

const VERSIONS_FILE = path.join(__dirname, '../data/app_versions.json');
const APKS_DIR = path.join(__dirname, '../../uploads/apks');

function getVersionsData() {
  try {
    if (!fs.existsSync(VERSIONS_FILE)) {
      const defaultData = {
        customer_app: {
          appId: 'customer_app',
          appName: 'Locki Customer',
          version: '1.0.0',
          buildNumber: 1,
          apkFileName: 'customer_app.apk',
          changelog: 'Fast Rental Marketplace, Verified Local Stores & Kirana Shopping',
          isForceUpdate: false,
          updatedAt: new Date().toISOString()
        },
        partner_app: {
          appId: 'partner_app',
          appName: 'Locki Partner',
          version: '1.0.0',
          buildNumber: 1,
          apkFileName: 'partner_app.apk',
          changelog: 'Multi-Business Store Switcher, HTML Compressed Photo Upload & Child Category Inventory',
          isForceUpdate: false,
          updatedAt: new Date().toISOString()
        }
      };
      fs.writeFileSync(VERSIONS_FILE, JSON.stringify(defaultData, null, 2), 'utf8');
      return defaultData;
    }
    const content = fs.readFileSync(VERSIONS_FILE, 'utf8');
    return JSON.parse(content);
  } catch (err) {
    console.error('Error reading app_versions.json:', err);
    return {};
  }
}

function saveVersionsData(data) {
  try {
    fs.writeFileSync(VERSIONS_FILE, JSON.stringify(data, null, 2), 'utf8');
    return true;
  } catch (err) {
    console.error('Error saving app_versions.json:', err);
    return false;
  }
}

// GET /api/app-updates/check?appId=customer_app&buildNumber=1&version=1.0.0
exports.checkUpdate = (req, res) => {
  try {
    const { appId, buildNumber, version } = req.query;

    if (!appId || (appId !== 'customer_app' && appId !== 'partner_app')) {
      return res.status(400).json({
        success: false,
        message: "Valid 'appId' (customer_app or partner_app) is required"
      });
    }

    const versions = getVersionsData();
    const appRelease = versions[appId];

    if (!appRelease) {
      return res.status(404).json({
        success: false,
        hasUpdate: false,
        message: `No release data found for ${appId}`
      });
    }

    const clientBuild = parseInt(buildNumber, 10) || 1;
    const serverBuild = parseInt(appRelease.buildNumber, 10) || 1;

    // Build the dynamic APK download URL
    const protocol = req.protocol || 'http';
    const host = req.get('host') || 'localhost:5000';
    const downloadUrl = `${protocol}://${host}/api/app-updates/download/${appId}`;

    const hasUpdate = serverBuild > clientBuild;

    return res.json({
      success: true,
      hasUpdate: hasUpdate,
      appId: appId,
      appName: appRelease.appName,
      currentClientBuild: clientBuild,
      latestVersion: appRelease.version,
      latestBuildNumber: serverBuild,
      changelog: appRelease.changelog || 'Performance improvements and bug fixes',
      isForceUpdate: !!appRelease.isForceUpdate,
      apkUrl: downloadUrl,
      updatedAt: appRelease.updatedAt
    });
  } catch (err) {
    console.error('checkUpdate error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
};

// GET /api/app-updates/versions
exports.getVersions = (req, res) => {
  const versions = getVersionsData();
  res.json({ success: true, versions });
};

// POST /api/app-updates/release
// Body: { appId, version, buildNumber, changelog, isForceUpdate }
exports.releaseUpdate = (req, res) => {
  try {
    const { appId, version, buildNumber, changelog, isForceUpdate } = req.body;
    if (!appId || !version || !buildNumber) {
      return res.status(400).json({ success: false, message: 'appId, version, buildNumber are required' });
    }

    const versions = getVersionsData();
    versions[appId] = {
      ...(versions[appId] || {}),
      appId,
      appName: appId === 'customer_app' ? 'Locki Customer' : 'Locki Partner',
      version: version.toString().trim(),
      buildNumber: parseInt(buildNumber, 10),
      changelog: changelog || 'New updates and bug fixes',
      isForceUpdate: !!isForceUpdate,
      apkFileName: `${appId}.apk`,
      updatedAt: new Date().toISOString()
    };

    saveVersionsData(versions);
    res.json({ success: true, message: `Successfully released update for ${appId}`, release: versions[appId] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// GET /api/app-updates/download/:appId
exports.downloadApk = (req, res) => {
  const { appId } = req.params;
  const targetName = appId.endsWith('.apk') ? appId : `${appId}.apk`;
  const filePath = path.join(APKS_DIR, targetName);

  if (!fs.existsSync(filePath)) {
    return res.status(404).send(`APK file not found on server for ${appId}. Please build and deploy.`);
  }

  res.setHeader('Content-Disposition', `attachment; filename="${targetName}"`);
  res.setHeader('Content-Type', 'application/vnd.android.package-archive');
  res.sendFile(filePath);
};
