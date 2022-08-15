<?php
// Do not edit this file directly! It is automatically generated after every container start.
$plugin = ['Sightings_policy' => 3];

{% if ZEROMQ_ENABLED %}
$plugin['ZeroMQ_enable'] = true;
{% if ZEROMQ_USERNAME %}
$plugin['ZeroMQ_username'] = '{{ ZEROMQ_USERNAME }}';
$plugin['ZeroMQ_password'] = {{ ZEROMQ_PASSWORD | str }};
{% endif %}
$plugin['ZeroMQ_redis_host'] = '{{ REDIS_HOST }}';
$plugin['ZeroMQ_redis_port'] = 6379;
$plugin['ZeroMQ_redis_password'] = {{ REDIS_PASSWORD | str }};
$plugin['ZeroMQ_redis_database'] = 10;
{% endif %}

{% if MISP_MODULE_URL %}
$plugin['Action_services_enable'] = true;
$plugin['Action_services_url'] = '{{ MISP_MODULE_URL }}';
$plugin['Import_services_enable'] = true;
$plugin['Import_services_url'] = '{{ MISP_MODULE_URL }}';
$plugin['Export_services_enable'] = true;
$plugin['Export_services_url'] = '{{ MISP_MODULE_URL }}';
$plugin['Enrichment_services_enable'] = true;
$plugin['Enrichment_hover_enable'] = true;
$plugin['Enrichment_hover_popover_only'] = false;
$plugin['Enrichment_cve_enabled'] = true;
$plugin['Enrichment_dns_enabled'] = true;
$plugin['Enrichment_services_url'] = '{{ MISP_MODULE_URL }}';
$plugin['Cortex_services_enable'] = false;
{% endif %}

{% if MISP_ATTACHMENT_SCAN_MODULE %}
$plugin['Enrichment_clamav_connection'] = 'unix:///run/clamd.scan/clamd.sock';
{% endif %}

{% if OIDC_LOGIN %}
$oidcAuth = [
    'provider_url' => '{{ OIDC_PROVIDER_INNER }}',
    'client_id' => '{{ OIDC_CLIENT_ID_INNER }}',
    'client_secret' => '{{ OIDC_CLIENT_SECRET_INNER }}',
    'authentication_method' => {{ OIDC_AUTHENTICATION_METHOD_INNER | str }},
    'code_challenge_method' => {{ OIDC_CODE_CHALLENGE_METHOD_INNER | str }},
    'role_mapper' => [
        'misp-admin-access' => 1, // Admin
        'misp-org-admin-access' => 2, // Org Admin
        'misp-sync-access' => 5, // Sync user
        'misp-publisher-access' => 4, // Publisher
        'misp-api-access' => 'User with API access',
        'misp-access' => 3, // User
    ],
    'organisation_property' => {{ OIDC_ORGANISATION_PROPERTY | str }},
    'default_org' => '{{ OIDC_DEFAULT_ORG if OIDC_DEFAULT_ORG else MISP_ORG }}',
    'unblock' => true,
    'offline_access' => {{ OIDC_OFFLINE_ACCESS | bool }},
    'check_user_validity' => {{ OIDC_CHECK_USER_VALIDITY }},
];
$plugin['CustomAuth_custom_logout'] = "{{ MISP_BASEURL }}/oauth2callback?logout={{ MISP_BASEURL | urlencode }}";
$plugin['CustomAuth_custom_password_reset'] = {{ OIDC_PASSWORD_RESET | str }};
{% else %}
$oidcAuth = NULL;
{% endif %}

$config = [
  'debug' => {{ 1 if MISP_DEBUG else 0 }},
  'MISP' => [
    'osuser' => 'apache',
    'baseurl' => '{{ MISP_BASEURL }}',
    'external_baseurl' => '{{ MISP_EXTERNAL_BASEURL if MISP_EXTERNAL_BASEURL else MISP_BASEURL }}',
    'live' => true,
    'org' => '{{ MISP_ORG }}',
    'title_text' => 'MISP {{ MISP_ORG }}',
    'showorg' => true,
    'language' => 'eng',
    'showCorrelationsOnIndex' => true,
    'showSightingsCountOnIndex' => true,
    'store_api_access_time' => true,
    'log_auth' => true,
    'log_client_ip' => true,
    'log_user_ips' => true,
    'log_user_ips_authkeys' => true,
    'log_new_audit' => true,
    'log_new_audit_compress' => true,
    'event_alert_metadata_only' => true,
    'email_reply_to' => {{ MISP_EMAIL_REPLY_TO | str }},
    'background_jobs' => true,
    'email' => '{{ MISP_ADMIN_EMAIL }}',
    'email_from_name' => '{{ MISP_ORG }} MISP',
    'contact' => '{{ MISP_ADMIN_EMAIL }}',
    'disablerestalert' => false,
    'default_event_distribution' => '0',
    'default_attribute_distribution' => 'event',
    'tagging' => true,
    'full_tags_on_event_index' => true,
    'default_event_tag_collection' => 0,
    'attribute_tagging' => true,
    'full_tags_on_attribute_index' => true,
    'take_ownership_xml_import' => false,
    'unpublishedprivate' => true,
    'allow_disabling_correlation' => false,
    'uuid' => '{{ MISP_UUID }}',
    'host_org_id' => {{ MISP_HOST_ORG_ID }},
    'redis_host' => '{{ REDIS_HOST }}',
    'redis_port' => 6379,
    'redis_database' => 13,
    'redis_password' => {{ REDIS_PASSWORD | str }},
    'proposals_block_attributes' => false,
    'attachment_scan_module' => {{ MISP_ATTACHMENT_SCAN_MODULE | str }},
    'attachments_dir' => '/var/www/MISP/app/attachments',
    'ca_path' => '/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem',
    'disable_user_login_change' => {{ OIDC_LOGIN | bool }},
    'disable_user_password_change' => {{ OIDC_LOGIN | bool }},
    'disable_user_add' => {{ OIDC_LOGIN | bool }},
    'download_gpg_from_homedir' => true,
    'enable_advanced_correlations' => true,
    'disable_cached_exports' => true,
    'allow_disabling_correlation' => false,
    'system_setting_db' => true,
    'default_publish_alert' => {{ MISP_DEFAULT_PUBLISH_ALERT | bool }},
    'terms_file' => {{ MISP_TERMS_FILE | str }},
    'home_logo' => {{ MISP_HOME_LOGO | str }},
    'footer_logo' => {{ MISP_FOOTER_LOGO | str }},
    'custom_css' => {{ MISP_CUSTOM_CSS | str }},
    'tmpdir' => '/tmp',
  ],
  'SimpleBackgroundJobs' => [
    'enabled' => true,
    'redis_host' => '{{ REDIS_HOST }}',
    'redis_port' => 6379,
    'redis_password' => {{ REDIS_PASSWORD | str }},
    'redis_database' => 11,
    'redis_namespace' => 'background_jobs',
    'redis_read_timeout' => 60.0,
    'max_job_history_ttl' => 86400,
    'supervisor_host' => 'unix:///run/supervisor/supervisor.sock',
    'supervisor_port' => 9001,
    'supervisor_user' => 'root',
    'supervisor_password' => '',
  ],
  'GnuPG' => [
    'onlyencrypted' => false,
    'email' => '{{ MISP_ADMIN_EMAIL }}',
    'homedir' => '/var/www/MISP/.gnupg',
    'password' => {{ GNUPG_PRIVATE_KEY_PASSWORD | str }},
    'bodyonlyencrypted' => {{ GNUPG_BODY_ONLY_ENCRYPTED | bool }},
    'sign' => {{ GNUPG_SIGN | bool }},
  ],
  'SMIME' => [
    'enabled' => false,
  ],
  {% if PROXY_HOST %}
  'Proxy' => [
    'host' => {{ PROXY_HOST | str }},
    'port' => {{ PROXY_PORT if PROXY_PORT else null }},
    'method' => {{ PROXY_METHOD | str }},
    'user' => {{ PROXY_USER | str }},
    'password' => {{ PROXY_PASSWORD | str }},
  ],
  {% endif %}
  'SecureAuth' => [
    'amount' => 5,
    'expire' => 300,
  ],
  'Security' => [
    'force_https' => {{ 'true' if MISP_BASEURL.startswith('https://') else 'false' }},
    'csp_enforce' => true,
    'min_tls_version' => 'tlsv1_2',
    'require_password_confirmation' => {{ 'false' if OIDC_LOGIN else 'true' }},
    'syslog' => true,
    'syslog_to_stderr' => false,
    'syslog_ident' => 'misp-audit',
    'level' => 'medium',
    'salt' => '{{ SECURITY_SALT }}',
    'encryption_key' => {{ SECURITY_ENCRYPTION_KEY | str }},
    'authkey_keep_session' => true,
    'do_not_log_authkeys' => true,
    'disable_browser_cache' => true,
    'check_sec_fetch_site_header' => true,
    'rest_client_baseurl' => '{{ "https://localhost" if MISP_BASEURL.startswith("https://") else "http://localhost" }}',
    'advanced_authkeys_validity' => 547,
    'user_monitoring_enabled' => true,
    'username_in_response_header' => true,
    'hide_organisation_index_from_users' => {{ SECURITY_HIDE_ORGS | bool }},
    'hide_organisations_in_sharing_groups' => {{ SECURITY_HIDE_ORGS | bool }},
    'advanced_authkeys' => {{ SECURITY_ADVANCED_AUTHKEYS | bool }},
    {% if OIDC_LOGIN %}
    'auth' => ['OidcAuth.Oidc'],
    'auth_enforced' => true,
    {% endif %}
  ],
  'Session' => [
    'defaults' => 'php',
    'timeout' => 60,
    'cookieTimeout' => 0,
    'autoRegenerate' => false,
    'checkAgent' => false,
    'cookie' => '{{ SECURITY_COOKIE_NAME }}',
  ],
  'Plugin' => $plugin,
  'OidcAuth' => $oidcAuth,
];

{% if SENTRY_DSN %}
// NUKIB custom variable
$config['MISP']['sentry_dsn'] = '{{ SENTRY_DSN }}';
{% if SENTRY_ENVIRONMENT %}
$config['MISP']['sentry_environment'] = '{{ SENTRY_ENVIRONMENT }}';
{% endif %}
{% endif %}
