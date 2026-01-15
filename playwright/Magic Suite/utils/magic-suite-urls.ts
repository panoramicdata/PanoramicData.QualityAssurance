/**
 * Magic Suite Deep Link URLs Registry
 * 
 * Comprehensive list of all deep link URLs across Magic Suite products.
 * Organized by product area for easy access in Playwright tests and regression testing.
 * 
 * Usage:
 *   import { getMagicSuiteUrl, MagicSuiteUrls } from './utils/magic-suite-urls';
 *   
 *   // Get specific URL
 *   const networksUrl = getMagicSuiteUrl('data', 'networks', 'alpha2');
 *   
 *   // Or use direct path
 *   const url = MagicSuiteUrls.data.networks('alpha2');
 */

import type { Environment } from './urls';

export type MagicSuiteProduct = 'www' | 'data' | 'alert' | 'report' | 'docs' | 'admin' | 'connect';

/**
 * Base URL builder for Magic Suite products
 */
function getBaseUrl(product: MagicSuiteProduct, env?: Environment): string {
  const environment = env || process.env.MS_ENV || 'alpha2';
  
  if (environment === 'production') {
    return `https://${product}.magicsuite.net`;
  }
  
  return `https://${product}.${environment}.magicsuite.net`;
}

/**
 * DataMagic Deep Links
 * Data source management and configuration
 */
export const DataMagicUrls = {
  home: (env?: Environment) => getBaseUrl('data', env),
  networks: (env?: Environment) => `${getBaseUrl('data', env)}/networks`,
  devices: (env?: Environment) => `${getBaseUrl('data', env)}/devices`,
  collectors: (env?: Environment) => `${getBaseUrl('data', env)}/collectors`,
  datasources: (env?: Environment) => `${getBaseUrl('data', env)}/datasources`,
  dataCollectorGroups: (env?: Environment) => `${getBaseUrl('data', env)}/dataCollectorGroups`,
  deviceGroups: (env?: Environment) => `${getBaseUrl('data', env)}/deviceGroups`,
  
  // Specific network by ID
  networkById: (id: string | number, env?: Environment) => `${getBaseUrl('data', env)}/networks/${id}`,
  
  // Device details
  deviceById: (id: string | number, env?: Environment) => `${getBaseUrl('data', env)}/devices/${id}`,
  deviceProperties: (id: string | number, env?: Environment) => `${getBaseUrl('data', env)}/devices/${id}/properties`,
  deviceAlerts: (id: string | number, env?: Environment) => `${getBaseUrl('data', env)}/devices/${id}/alerts`,
  
  // Collector details
  collectorById: (id: string | number, env?: Environment) => `${getBaseUrl('data', env)}/collectors/${id}`,
  
  // Settings and configuration
  settings: (env?: Environment) => `${getBaseUrl('data', env)}/settings`,
  apiTokens: (env?: Environment) => `${getBaseUrl('data', env)}/settings/tokens`,
};

/**
 * ReportMagic Deep Links
 * Report creation, scheduling, and management
 */
export const ReportMagicUrls = {
  home: (env?: Environment) => getBaseUrl('report', env),
  
  // Report Studio
  studio: (env?: Environment) => `${getBaseUrl('report', env)}/studio`,
  studioNew: (env?: Environment) => `${getBaseUrl('report', env)}/studio/new`,
  studioById: (id: string | number, env?: Environment) => `${getBaseUrl('report', env)}/studio/${id}`,
  
  // Report Management
  reports: (env?: Environment) => `${getBaseUrl('report', env)}/reports`,
  reportById: (id: string | number, env?: Environment) => `${getBaseUrl('report', env)}/reports/${id}`,
  reportEdit: (id: string | number, env?: Environment) => `${getBaseUrl('report', env)}/reports/${id}/edit`,
  reportRun: (id: string | number, env?: Environment) => `${getBaseUrl('report', env)}/reports/${id}/run`,
  
  // Schedules
  schedules: (env?: Environment) => `${getBaseUrl('report', env)}/schedules`,
  scheduleNew: (env?: Environment) => `${getBaseUrl('report', env)}/schedules/new`,
  scheduleById: (id: string | number, env?: Environment) => `${getBaseUrl('report', env)}/schedules/${id}`,
  scheduleEdit: (id: string | number, env?: Environment) => `${getBaseUrl('report', env)}/schedules/${id}/edit`,
  
  // Report History & Outputs
  history: (env?: Environment) => `${getBaseUrl('report', env)}/history`,
  outputs: (env?: Environment) => `${getBaseUrl('report', env)}/outputs`,
  
  // Templates and Macros
  templates: (env?: Environment) => `${getBaseUrl('report', env)}/templates`,
  macros: (env?: Environment) => `${getBaseUrl('report', env)}/macros`,
  
  // Settings
  settings: (env?: Environment) => `${getBaseUrl('report', env)}/settings`,
  connections: (env?: Environment) => `${getBaseUrl('report', env)}/settings/connections`,
};

/**
 * AlertMagic Deep Links
 * Alert configuration and incident management
 */
export const AlertMagicUrls = {
  home: (env?: Environment) => getBaseUrl('alert', env),
  
  // Alerts and Incidents
  alerts: (env?: Environment) => `${getBaseUrl('alert', env)}/alerts`,
  incidents: (env?: Environment) => `${getBaseUrl('alert', env)}/incidents`,
  incidentById: (id: string | number, env?: Environment) => `${getBaseUrl('alert', env)}/incidents/${id}`,
  
  // Alert Rules
  rules: (env?: Environment) => `${getBaseUrl('alert', env)}/rules`,
  ruleNew: (env?: Environment) => `${getBaseUrl('alert', env)}/rules/new`,
  ruleById: (id: string | number, env?: Environment) => `${getBaseUrl('alert', env)}/rules/${id}`,
  ruleEdit: (id: string | number, env?: Environment) => `${getBaseUrl('alert', env)}/rules/${id}/edit`,
  
  // Alert Channels
  channels: (env?: Environment) => `${getBaseUrl('alert', env)}/channels`,
  channelNew: (env?: Environment) => `${getBaseUrl('alert', env)}/channels/new`,
  channelById: (id: string | number, env?: Environment) => `${getBaseUrl('alert', env)}/channels/${id}`,
  
  // Escalation Chains
  escalations: (env?: Environment) => `${getBaseUrl('alert', env)}/escalations`,
  escalationNew: (env?: Environment) => `${getBaseUrl('alert', env)}/escalations/new`,
  escalationById: (id: string | number, env?: Environment) => `${getBaseUrl('alert', env)}/escalations/${id}`,
  
  // Alert Settings
  settings: (env?: Environment) => `${getBaseUrl('alert', env)}/settings`,
};

/**
 * Admin Portal Deep Links
 * Tenant, user, and system administration
 */
export const AdminUrls = {
  home: (env?: Environment) => getBaseUrl('admin', env),
  
  // Tenant Management
  tenants: (env?: Environment) => `${getBaseUrl('admin', env)}/tenants`,
  tenantNew: (env?: Environment) => `${getBaseUrl('admin', env)}/tenants/new`,
  tenantById: (id: string | number, env?: Environment) => `${getBaseUrl('admin', env)}/tenants/${id}`,
  tenantEdit: (id: string | number, env?: Environment) => `${getBaseUrl('admin', env)}/tenants/${id}/edit`,
  
  // User Management
  users: (env?: Environment) => `${getBaseUrl('admin', env)}/users`,
  userNew: (env?: Environment) => `${getBaseUrl('admin', env)}/users/new`,
  userById: (id: string | number, env?: Environment) => `${getBaseUrl('admin', env)}/users/${id}`,
  userEdit: (id: string | number, env?: Environment) => `${getBaseUrl('admin', env)}/users/${id}/edit`,
  
  // Role Management (RBAC)
  roles: (env?: Environment) => `${getBaseUrl('admin', env)}/roles`,
  roleNew: (env?: Environment) => `${getBaseUrl('admin', env)}/roles/new`,
  roleById: (id: string | number, env?: Environment) => `${getBaseUrl('admin', env)}/roles/${id}`,
  
  // Permissions
  permissions: (env?: Environment) => `${getBaseUrl('admin', env)}/permissions`,
  
  // API Tokens (System-wide)
  apiTokens: (env?: Environment) => `${getBaseUrl('admin', env)}/api-tokens`,
  
  // Audit Logs
  auditLogs: (env?: Environment) => `${getBaseUrl('admin', env)}/audit`,
  
  // System Settings
  settings: (env?: Environment) => `${getBaseUrl('admin', env)}/settings`,
  systemHealth: (env?: Environment) => `${getBaseUrl('admin', env)}/system/health`,
};

/**
 * Connect Portal Deep Links
 * Integration and connector management
 */
export const ConnectUrls = {
  home: (env?: Environment) => getBaseUrl('connect', env),
  
  // Connectors
  connectors: (env?: Environment) => `${getBaseUrl('connect', env)}/connectors`,
  connectorNew: (env?: Environment) => `${getBaseUrl('connect', env)}/connectors/new`,
  connectorById: (id: string | number, env?: Environment) => `${getBaseUrl('connect', env)}/connectors/${id}`,
  
  // Integrations
  integrations: (env?: Environment) => `${getBaseUrl('connect', env)}/integrations`,
  integrationNew: (env?: Environment) => `${getBaseUrl('connect', env)}/integrations/new`,
  integrationById: (id: string | number, env?: Environment) => `${getBaseUrl('connect', env)}/integrations/${id}`,
  
  // Webhooks
  webhooks: (env?: Environment) => `${getBaseUrl('connect', env)}/webhooks`,
  webhookNew: (env?: Environment) => `${getBaseUrl('connect', env)}/webhooks/new`,
  webhookById: (id: string | number, env?: Environment) => `${getBaseUrl('connect', env)}/webhooks/${id}`,
  
  // Settings
  settings: (env?: Environment) => `${getBaseUrl('connect', env)}/settings`,
};

/**
 * Documentation Deep Links
 * Product documentation and help resources
 */
export const DocsUrls = {
  home: (env?: Environment) => getBaseUrl('docs', env),
  
  // Product Documentation
  datamagic: (env?: Environment) => `${getBaseUrl('docs', env)}/datamagic`,
  reportmagic: (env?: Environment) => `${getBaseUrl('docs', env)}/reportmagic`,
  alertmagic: (env?: Environment) => `${getBaseUrl('docs', env)}/alertmagic`,
  
  // ReportMagic specific docs
  reportMagicMacros: (env?: Environment) => `${getBaseUrl('docs', env)}/reportmagic/macros`,
  reportMagicFunctions: (env?: Environment) => `${getBaseUrl('docs', env)}/reportmagic/functions`,
  reportMagicExamples: (env?: Environment) => `${getBaseUrl('docs', env)}/reportmagic/examples`,
  
  // API Documentation
  api: (env?: Environment) => `${getBaseUrl('docs', env)}/api`,
  apiReference: (env?: Environment) => `${getBaseUrl('docs', env)}/api/reference`,
  
  // Guides
  gettingStarted: (env?: Environment) => `${getBaseUrl('docs', env)}/getting-started`,
  tutorials: (env?: Environment) => `${getBaseUrl('docs', env)}/tutorials`,
  
  // Release Notes
  releaseNotes: (env?: Environment) => `${getBaseUrl('docs', env)}/release-notes`,
  changelog: (env?: Environment) => `${getBaseUrl('docs', env)}/changelog`,
};

/**
 * Main Portal (www) Deep Links
 * Dashboard, profile, and general navigation
 */
export const MainPortalUrls = {
  home: (env?: Environment) => getBaseUrl('www', env),
  
  // Dashboard
  dashboard: (env?: Environment) => `${getBaseUrl('www', env)}/dashboard`,
  
  // User Profile
  profile: (env?: Environment) => `${getBaseUrl('www', env)}/profile`,
  profileEdit: (env?: Environment) => `${getBaseUrl('www', env)}/profile/edit`,
  profileSettings: (env?: Environment) => `${getBaseUrl('www', env)}/profile/settings`,
  profileTokens: (env?: Environment) => `${getBaseUrl('www', env)}/profile/tokens`,
  
  // Account Management
  account: (env?: Environment) => `${getBaseUrl('www', env)}/account`,
  billing: (env?: Environment) => `${getBaseUrl('www', env)}/account/billing`,
  subscription: (env?: Environment) => `${getBaseUrl('www', env)}/account/subscription`,
  
  // Product Navigation
  products: (env?: Environment) => `${getBaseUrl('www', env)}/products`,
  
  // Feedback
  feedback: (env?: Environment) => `${getBaseUrl('www', env)}/feedback`,
  
  // Support
  support: (env?: Environment) => `${getBaseUrl('www', env)}/support`,
  contactUs: (env?: Environment) => `${getBaseUrl('www', env)}/contact`,
};

/**
 * Special URLs - External and Utility
 */
export const SpecialUrls = {
  // NCalc 101 - Expression language learning
  ncalc101: (env?: Environment) => {
    // NCalc 101 doesn't have environment variations
    return 'https://ncalc101.magicsuite.net';
  },
  
  // API Endpoints
  api: (env?: Environment) => {
    const environment = env || process.env.MS_ENV || 'alpha2';
    if (environment === 'production') {
      return 'https://api.magicsuite.net';
    }
    return `https://api.${environment}.magicsuite.net`;
  },
};

/**
 * Complete URL Registry
 * Organized by product for easy access
 */
export const MagicSuiteUrls = {
  data: DataMagicUrls,
  report: ReportMagicUrls,
  alert: AlertMagicUrls,
  admin: AdminUrls,
  connect: ConnectUrls,
  docs: DocsUrls,
  www: MainPortalUrls,
  special: SpecialUrls,
};

/**
 * Helper function to get any Magic Suite URL
 * 
 * @param product - The Magic Suite product (data, report, alert, etc.)
 * @param page - The specific page or feature
 * @param env - Environment (alpha, alpha2, test2, production, etc.)
 * @param id - Optional ID for specific resources
 */
export function getMagicSuiteUrl(
  product: keyof typeof MagicSuiteUrls,
  page: string,
  env?: Environment,
  id?: string | number
): string {
  const productUrls = MagicSuiteUrls[product];
  
  if (!productUrls) {
    throw new Error(`Unknown product: ${product}`);
  }
  
  const urlFunction = productUrls[page as keyof typeof productUrls];
  
  if (typeof urlFunction !== 'function') {
    throw new Error(`Unknown page "${page}" for product "${product}"`);
  }
  
  // @ts-ignore - Dynamic function call
  return id ? urlFunction(id, env) : urlFunction(env);
}

/**
 * Get all URLs for a specific environment (useful for regression testing)
 * 
 * @param env - Environment to get URLs for
 * @returns Object containing all URLs for the environment
 */
export function getAllUrlsForEnvironment(env?: Environment): Record<string, string> {
  const urls: Record<string, string> = {};
  
  // DataMagic
  urls['data_home'] = DataMagicUrls.home(env);
  urls['data_networks'] = DataMagicUrls.networks(env);
  urls['data_devices'] = DataMagicUrls.devices(env);
  urls['data_collectors'] = DataMagicUrls.collectors(env);
  urls['data_datasources'] = DataMagicUrls.datasources(env);
  urls['data_settings'] = DataMagicUrls.settings(env);
  
  // ReportMagic
  urls['report_home'] = ReportMagicUrls.home(env);
  urls['report_studio'] = ReportMagicUrls.studio(env);
  urls['report_reports'] = ReportMagicUrls.reports(env);
  urls['report_schedules'] = ReportMagicUrls.schedules(env);
  urls['report_history'] = ReportMagicUrls.history(env);
  
  // AlertMagic
  urls['alert_home'] = AlertMagicUrls.home(env);
  urls['alert_alerts'] = AlertMagicUrls.alerts(env);
  urls['alert_incidents'] = AlertMagicUrls.incidents(env);
  urls['alert_rules'] = AlertMagicUrls.rules(env);
  urls['alert_channels'] = AlertMagicUrls.channels(env);
  
  // Admin
  urls['admin_home'] = AdminUrls.home(env);
  urls['admin_tenants'] = AdminUrls.tenants(env);
  urls['admin_users'] = AdminUrls.users(env);
  urls['admin_roles'] = AdminUrls.roles(env);
  
  // Connect
  urls['connect_home'] = ConnectUrls.home(env);
  urls['connect_connectors'] = ConnectUrls.connectors(env);
  urls['connect_integrations'] = ConnectUrls.integrations(env);
  
  // Docs
  urls['docs_home'] = DocsUrls.home(env);
  urls['docs_api'] = DocsUrls.api(env);
  urls['docs_reportmagic_macros'] = DocsUrls.reportMagicMacros(env);
  
  // Main Portal
  urls['www_home'] = MainPortalUrls.home(env);
  urls['www_dashboard'] = MainPortalUrls.dashboard(env);
  urls['www_profile'] = MainPortalUrls.profile(env);
  
  return urls;
}

/**
 * Validate that a URL is accessible (returns 200 OK)
 * Useful for regression testing
 * 
 * @param url - The URL to check
 * @returns Promise<boolean> - True if URL is accessible
 */
export async function validateUrl(url: string): Promise<{ url: string; ok: boolean; status: number }> {
  try {
    const response = await fetch(url, { method: 'HEAD' });
    return {
      url,
      ok: response.ok,
      status: response.status
    };
  } catch (error) {
    return {
      url,
      ok: false,
      status: 0
    };
  }
}

export default MagicSuiteUrls;
