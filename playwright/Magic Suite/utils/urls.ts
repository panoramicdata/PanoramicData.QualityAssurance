/**
 * URL mapping utilities for Magic Suite environments
 */

export type Environment = 'alpha' | 'alpha2' | 'alpha3' | 'test' | 'test2' | 'beta' | 'staging' | 'ps' | 'production';
export type AppPrefix = 'www' | 'data' | 'alert' | 'report' | 'docs' | 'admin' | 'connect';

/**
 * Get the full URL for a Magic Suite app in a specific environment
 * @param appPrefix - The app subdomain (www, data, alert, etc.)
 * @param env - The environment name
 * @returns The full URL
 */
export function getAppUrl(appPrefix: AppPrefix, env?: string): string {
  const environment = (env || process.env.MS_ENV || 'alpha2') as string;
  
  // Special URL mappings for environments with non-standard naming
  const specialMappings: { [key: string]: { [key in AppPrefix]?: string } } = {
    'alpha2': {
      'www': 'https://www.alpha2.magicsuite.net',
      'data': 'https://data.alpha2.magicsuite.net',
      'alert': 'https://alert.alpha2.magicsuite.net',
      'report': 'https://report.alpha2.magicsuite.net',
      'docs': 'https://docs.alpha2.magicsuite.net',
      'admin': 'https://admin.alpha2.magicsuite.net',
      'connect': 'https://connect.alpha2.magicsuite.net',
    },
    'alpha3': {
      'www': 'https://www.alpha3.magicsuite.net',
      'data': 'https://data.alpha3.magicsuite.net',
      'alert': 'https://alert.alpha3.magicsuite.net',
      'report': 'https://report.alpha3.magicsuite.net',
      'docs': 'https://docs.alpha3.magicsuite.net',
      'admin': 'https://admin.alpha3.magicsuite.net',
      'connect': 'https://connect.alpha3.magicsuite.net',
    },
    'test2': {
      'www': 'https://www.test2.magicsuite.net',
      'data': 'https://data.test2.magicsuite.net',
      'alert': 'https://alert.test2.magicsuite.net',
      'report': 'https://report.test2.magicsuite.net',
      'docs': 'https://docs.test2.magicsuite.net',
      'admin': 'https://admin.test2.magicsuite.net',
      'connect': 'https://connect.test2.magicsuite.net',
    },
    'ps': {
      'www': 'https://www.ps.magicsuite.net',
      'data': 'https://data.ps.magicsuite.net',
      'alert': 'https://alert.ps.magicsuite.net',
      'report': 'https://report.ps.magicsuite.net',
      'docs': 'https://docs.ps.magicsuite.net',
      'admin': 'https://admin.ps.magicsuite.net',
      'connect': 'https://connect.ps.magicsuite.net',
    },
    'production': {
      'www': 'https://www.magicsuite.net',
      'data': 'https://data.magicsuite.net',
      'alert': 'https://alert.magicsuite.net',
      'report': 'https://report.magicsuite.net',
      'docs': 'https://docs.magicsuite.net',
      'admin': 'https://admin.magicsuite.net',
      'connect': 'https://connect.magicsuite.net',
    }
  };
  
  // Check if there's a special mapping for this environment
  if (specialMappings[environment]?.[appPrefix]) {
    return specialMappings[environment][appPrefix]!;
  }
  
  // Standard naming: https://{app}.{env}.magicsuite.net or https://{app}.magicsuite.net for production
  if (environment === 'production') {
    return `https://${appPrefix}.magicsuite.net`;
  }
  
  return `https://${appPrefix}.${environment}.magicsuite.net`;
}

/**
 * Get the login URL for a specific environment
 * @param env - The environment name
 * @returns The login URL (www subdomain)
 */
export function getLoginUrl(env?: string): string {
  return getAppUrl('www', env);
}
