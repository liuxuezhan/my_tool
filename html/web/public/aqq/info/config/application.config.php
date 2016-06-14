<?php
define('TX_PLATFORM_WEIXIN', 1);
define('TX_PLATFORM_QQ', 2);
define('TX_PLATFORM_WTLOGIN', 3);
define('TX_PLATFORM_QQHALL', 4);
define('TX_PLATFORM_GUEST', 5);

define('TX_CODE_SUCCESS',0);

define('WX_APPID', 'wx948cedfeba1726ca');
define('WX_APPKEY', 'a2690a827067b0693b3e051bb41acf1a');
define('QQ_APPID', 1000002010);
define('QQ_APPKEY', 'AEUqTx4jbNoJhwax');

define('IOS_PAYID', 1450001466);

define('AREA_ID_WX', 1);
define('AREA_ID_QQ', 2);

define('MSDK_OS_IOS', 0);//MSDK-iOS
define('MSDK_OS_ANDROID', 1);//MSDK-Android

define('PLAT_ID_IOS', 0);//IDIP-iOS
define('PLAT_ID_ANDROID', 1);//IDIP-Android

define('CX_SIG_CERTIFY_KEY', 'da1b52975d14c27c6b0b117bec7f1f3b');
define('CX_SIG_PAY_KEY', 'eaab6005273c729da3bf2c55e25eb936');
define('CX_SIG_RELATION_KEY', '801a1f9ee7b1eedef226c9694f5767f6');
define('CX_CODE_SUCCESS',1);
define('CX_CODE_FAILED',0);

define('AQQ_HOST', 'msdktest.qq.com');

return array(
    // This should be an array of module namespaces used in the application.
    'modules' => array(
        'Application',
        'User',
        'Account',
        'Idip',
        'Gateway',
    ),

    // These are various options for the listeners attached to the ModuleManager
    'module_listener_options' => array(
        // This should be an array of paths in which modules reside.
        // If a string key is provided, the listener will consider that a module
        // namespace, the value of that key the specific path to that module's
        // Module class.
        'module_paths' => array(
            './module',
            './vendor',
        ),

        // An array of paths from which to glob configuration files after
        // modules are loaded. These effectively override configuration
        // provided by modules themselves. Paths may use GLOB_BRACE notation.
        'config_glob_paths' => array(
            #'config/autoload/{,*.}{global,local}.php',
            sprintf('config/autoload/{,*.}{global,%s,local}.php', getenv('APPLICATION_ENV'))
        ),

        // Whether or not to enable a configuration cache.
        // If enabled, the merged configuration will be cached and used in
        // subsequent requests.
        //'config_cache_enabled' => $booleanValue,
        'config_cache_enabled'  => false,

        // The key used to create the configuration cache file name.
        //'config_cache_key' => $stringKey,
        'config_cache_key'          => 'config_cache',

        // Whether or not to enable a module class map cache.
        // If enabled, creates a module class map cache which will be used
        // by in future requests, to reduce the autoloading process.
        //'module_map_cache_enabled' => $booleanValue,
        'module_map_cache_enabled' => false,

        // The key used to create the class map cache file name.
        //'module_map_cache_key' => $stringKey,
        'module_map_cache_key' => 'module_map_cache',

        // The path in which to cache merged configuration.
        //'cache_dir' => $stringPath,
        'cache_dir'                 => './data/cache',

        // Whether or not to enable modules dependency checking.
        // Enabled by default, prevents usage of modules that depend on other modules
        // that weren't loaded.
        // 'check_dependencies' => true,
    ),

    // Used to create an own service manager. May contain one or more child arrays.
    //'service_listener_options' => array(
    //     array(
    //         'service_manager' => $stringServiceManagerName,
    //         'config_key'      => $stringConfigKey,
    //         'interface'       => $stringOptionalInterface,
    //         'method'          => $stringRequiredMethodName,
    //     ),
    // )

   // Initial configuration with which to seed the ServiceManager.
   // Should be compatible with Zend\ServiceManager\Config.
   // 'service_manager' => array(),
   
);
